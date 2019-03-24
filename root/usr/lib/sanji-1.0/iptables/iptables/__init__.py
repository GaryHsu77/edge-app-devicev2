#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import logging
import os
import sh
from threading import Event
import time

from voluptuous import Schema, Optional, Required, In, Any, All, Length, \
    Extra, Invalid, REMOVE_EXTRA

import iptable

_logger = logging.getLogger("sanji.iptables")


def Ports(delim=":"):
    """Port range verification function.
    The format should be: <start port>[delim<end port>]

    Args:
        delim: delimiter for port range
    """
    def f(v):
        msg = "invalid port format; should be integer between 1 and 65535"
        ports = str(v).split(delim)
        if len(ports) > 2:
            raise Invalid(msg)
        for entry in ports:
            if entry.isdigit() is False:
                raise Invalid(msg)
            port = int(entry)
            if port < 1 or port > 65535:
                raise Invalid(msg)
        return str(v)
    return f


def Mark():
    def f(v):
        return str(v)
    return f


FILTER_SCHEMA = Schema({
    "id": int,
    Required("chain"): In(frozenset(["INPUT", "OUTPUT", "FORWARD"])),
    Required("target"): In(frozenset(["ACCEPT", "DROP", "REJECT"])),
    Optional("protocol"): All(Any(unicode, str), Length(1, 255)),
    Optional("match"): All(Any(unicode, str), Length(1, 255)),
    Optional("in-interface"): All(Any(unicode, str), Length(1, 255)),
    Optional("out-interface"): All(Any(unicode, str), Length(1, 255)),
    Optional("destination"): All(Any(unicode, str), Length(1, 255)),
    Optional("destination-port"): All(Ports()),
    Optional("source"): All(Any(unicode, str), Length(1, 255)),
    Optional("source-port"): All(Ports()),
    Extra: object
}, extra=REMOVE_EXTRA)

NAT_SCHEMA = Schema({
    "id": int,
    Required("chain"): In(frozenset(["PREROUTING", "OUTPUT", "POSTROUTING"])),
    Required("target"): In(frozenset(["DNAT", "REDIRECT", "SNAT",
                                     "MASQUERADE"])),
    Optional("in-interface"): All(Any(unicode, str), Length(1, 255)),
    Optional("out-interface"): All(Any(unicode, str), Length(1, 255)),
    Optional("destination"): All(Any(unicode, str), Length(1, 255)),
    Optional("destination-port"): All(Ports()),
    Optional("to-destination"): All(Any(unicode, str), Length(1, 255)),
    Optional("to-ports"): All(Ports("-")),
    Optional("source"): All(Any(unicode, str), Length(1, 255)),
    Optional("to-source"): All(Any(unicode, str), Length(1, 255)),
    Extra: object
}, extra=REMOVE_EXTRA)

MANGLE_SCHEMA = Schema({
    "id": int,
    Required("chain"): In(frozenset(["PREROUTING", "OUTPUT", "INPUT",
                                     "FORWARD", "POSTROUTING"])),
    Required("target"): In(frozenset(["DSCP", "ECN", "IPMARK", "MARK",
                                      "IPV4OPTSSTRIP", "TCPMSS", "TOS",
                                      "TTL"])),
    Optional("protocol"): All(Any(unicode, str), Length(1, 255)),
    Optional("source"): All(Any(unicode, str), Length(1, 255)),
    Optional("source-port"): All(Ports()),
    Optional("destination"): All(Any(unicode, str), Length(1, 255)),
    Optional("destination-port"): All(Ports()),
    Optional("set-mark"): All(Mark()),
    Optional("options"): All(Any(unicode, str), Length(1, 255)),
    Extra: object
}, extra=REMOVE_EXTRA)


class IPTablesBatch(object):

    def __init__(self, tables):
        self.enable = Event()
        self.tables = tables

    def __enter__(self):
        if self.enable.is_set():
            raise RuntimeError("Already in batch mode")
        self.enable.set()
        for table in self.tables:
            try:
                self.tables[table].batch().__enter__()
            except Exception:
                pass

    def __exit__(self, type, value, traceback):
        self.enable.clear()
        for table in self.tables:
            self.tables[table].batch().__exit__(None, None, None)


class IPTablesError(Exception):
    pass


class IPTables(object):

    iptables_path = "/etc/iptables/up.rules"
    iptables_hook_path = "/etc/iptables/run.sh"

    def __init__(self, *args, **kwargs):
        support_tables = [
            {"name": "filter", "schema": FILTER_SCHEMA},
            {"name": "nat", "schema": NAT_SCHEMA},
            {"name": "mangle", "schema": MANGLE_SCHEMA}
        ]

        self._get_network_status_cb = None

        # initialize iptables
        self.tables = {}
        for table in support_tables:
            self.tables[table["name"]] = \
                iptable.IPTable(name=table["name"], path=kwargs["path"],
                                schema=table["schema"])
        self._batch = IPTablesBatch(self.tables)
        self._flush_sh_path = "{}/tools/flush.sh".format(kwargs["path"])
        self._flush_sh = sh.Command(self._flush_sh_path)

    def batch(self):
        return self._batch

    def _generate_rule_options(self, rule):
        option_mapping = [
            {"key": "in-interface", "option": "-i"},
            {"key": "protocol", "option": "-p"},
            {"key": "match", "option": "-m"},
            {"key": "source", "option": "-s"},
            {"key": "source-port", "option": "--sport"},
            {"key": "destination", "option": "--destination"},
            {"key": "destination-port", "option": "--dport"},
            {"key": "out-interface", "option": "-o"},
            {"key": "target", "option": "-j"},
            {"key": "to-destination", "option": "--to-destination"},
            {"key": "to-ports", "option": "--to-ports"},
            {"key": "set-mark", "option": "--set-mark"},
            {"key": "options", "option": ""}
        ]
        rule_opts = []
        if rule.get("default", None) is True:
            rule_opts.append("-P")
            rule_opts.append('MOXA-' + rule["chain"])
            rule_opts.append(rule["target"])
        else:
            rule_opts.append("-A")
            rule_opts.append('MOXA-' + rule["chain"])
            for opt in option_mapping:
                if opt["key"] in rule:
                    rule_opts.append(opt["option"])
                    if opt["key"] == "in-interface" or \
                            opt["key"] == "out-interface":
                        rule_opts.append(
                            self._map_actual_iface(rule[opt["key"]]))
                    else:
                        rule_opts.append(rule[opt["key"]])
        return rule_opts

    def _generate_config_by_table(self, table, fp):
        """Generate configuration contents by table

            Args:
                table: one of the table in iptables
                fp: file pointer
        """
        self._iface_mapping_dict = self._prepare_iface_mapping_dict()

        # collect chains
        rule_chains = set()
        for rule in sorted(
                table.getAll(),
                key=lambda x: x["priority"] if "priority" in x else 1):
            rule_chains.add('MOXA-' + rule['chain'])

        fp.write("*%s\n" % table.name)

        # create MOXA chains
        iptables_save_output = str(sh.iptables_save('-t', table.name))
        for chain in rule_chains:
            jump_rule = ' '.join(['-A', chain, '-j', 'MOXA-' + chain])
            if ':MOXA-' + chain not in iptables_save_output:
                fp.write(' '.join(['-N', 'MOXA-' + chain]))
                fp.write("\n")
                fp.write(jump_rule)
                fp.write("\n")

        # for rule in table.getAll():
        for rule in sorted(
                table.getAll(),
                key=lambda x: x["priority"] if "priority" in x else 1):
            fp.write(" ".join(self._generate_rule_options(rule)))
            fp.write("\n")

        # add return rule in MOXA chains
        for chain in rule_chains:
            fp.write(' '.join([
                '-A',
                'MOXA-' + chain,
                '-j',
                'RETURN',
            ]))
            fp.write("\n")
        fp.write("\n")
        fp.write("COMMIT\n")

    def _generate_config(self):
        """Generate configurations for `iptables` to `/etc/iptables/up.rules`
        """
        with open(self.iptables_path, "w") as fp:
            for table in self.tables:
                self._generate_config_by_table(self.tables[table], fp)
                fp.write("\n")

    def _map_actual_iface(self, iface):
        return self._iface_mapping_dict.get(iface, iface)

    def _prepare_iface_mapping_dict(self):
        nwk_status = self._get_network_status_cb()
        if "message" in nwk_status:
            time.sleep(1)
            nwk_status = self._get_network_status_cb()
        ifaces = {}
        for iface in nwk_status:
            actual = nwk_status[iface].get("actualIface", iface)
            ifaces[iface] = actual
        return ifaces

    def flush(self):
        """Flush all tables. """
        with self.batch():
            for table in self.tables:
                # FIXME: how about the default rule?
                '''
                # only mangle table use config's rules directly
                if table == "mangle":
                    continue
                '''
                self.tables[table].flush()
        try:
            os.remove(self.iptables_path)
        except OSError:
            pass

    def apply(self):
        """Update iptables' rules and restore it
            $ sudo iptables-save > /etc/iptables/iptables.rules
            $ sudo iptables-restore < /etc/iptables/iptables.rules
        """
        try:
            self._generate_config()
            self._flush_sh()
            with open(self.iptables_path) as fp:
                sh.iptables_restore('--noflush', _in=fp)
            # clean conntrack memorized rules
            try:
                _conntrack_cmd = sh.Command("/usr/sbin/conntrack")
                _conntrack_cmd("-D")
            except sh.ErrorReturnCode as e:
                _logger.warn(str(e))
        except Exception as e:
            _logger.error(str(e))
            raise e

        try:
            sh.sh("-c", self.iptables_hook_path, _timeout=60)
        except Exception as e:
            _logger.error(str(e))

    def get_all(self):
        """Get all iptables' rules, format will be
            {
                "filter": [],
                "nat": [],
                ...
            }
        """
        rules = {}
        for key in self.tables:
            rules[key] = self.tables[key].getAll()
        return rules

    def get_rules_by_table(self, table=None):
        """Get by table

            Args:
                table: name of the iptable
        """
        if table is None or table not in self.tables:
            return None

        return self.tables[table].getAll()

    def get_rule_by_id(self, table=None, id=1):
        """Get by table

            Args:
                table: name of the iptable
                id: rule identifier
        """
        if table is None or table not in self.tables:
            return None

        return self.tables[table].get(id=id)

    def update_rule_to_table(
            self, table=None, id=0, newObj=None, activate=True):
        """Update an exist rule.

            Args:
                table: name of the iptable
                id: rule identifier
                newObj: rule object to be updated
           Raises:
               TODO
        """
        if table is None or table not in self.tables:
            return None

        updated = self.tables[table].set(id=id, newObj=newObj)
        if updated is None:
            return None

        try:
            if activate is True:
                self.apply()
        except Exception as e:
            self.tables[table].remove(id=id)
            raise e
        return updated

    def add_rule_to_table(self, table=None, newObj=None, activate=True):
        """Add a rule.

            Args:
                table (str): table name
                newObj: rule object to be added
            Raises:
                TODO
        """
        if table is None or table not in self.tables:
            return None

        new = self.tables[table].add(obj=newObj)
        if new is None:
            return None

        try:
            if activate is True:
                self.apply()
        except Exception as e:
            self.tables[table].remove(id=new["id"])
            raise e
        return new

    def remove_rule_from_table(self, table=None, id=1, activate=True):
        """Get by table

            Args:
                table: name of the iptable
                id: rule identifier
        """
        if table is None or table not in self.tables:
            return None

        len = self.tables[table].remove(id=id)
        if activate is True:
            self.apply()
        return len

    def set_get_network_status_cb(self, callback):
        self._get_network_status_cb = callback