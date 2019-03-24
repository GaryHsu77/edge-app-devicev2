import os
import time
import datetime
import ctypes.util
from ctypes import (POINTER, c_ubyte, c_int, c_int64, c_uint64,
                    c_double, c_char_p, byref, c_void_p, CFUNCTYPE)
from enum import IntEnum
import struct

# Load libmxidaf by platform
if os.name == 'posix':
    path = ctypes.util.find_library('mxtagf')
    if path is None:
        raise ImportError('Could not find mxtagf, make sure it is installed')
    try:
        _libmxtagf = ctypes.cdll.LoadLibrary(path)
    except OSError:
        raise ImportError('Could not load mxtagf at "%s"' % path)
elif os.name == 'nt':
    try:
        _libmxtagf = ctypes.cdll.libmxtagf
    except:
        raise ImportError('Could not load mxtagf, make sure it is installed')
else:
    raise NotImplementedError('Libmxidaf is not supported on your platform')


# Enum of Data Type
class Type(IntEnum):
    INT = 0
    UINT = 1
    DOUBLE = 2
    STRING = 3
    BYTEARRAY = 4


# Definition of Byte data
class Bytes(ctypes.Structure):
    _fields_ = [("b", POINTER(c_ubyte)),
                ("len", c_int)]
    """def __init__(self, val, size):
        self.b = val
        self.len = size
    """


# Definition of Data Value
class Value(ctypes.Union):
    _fields_ = [
        ("i", c_int64),
        ("u", c_uint64),
        ("d", c_double),
        ("s", c_char_p),
        ("_b", Bytes)
    ]

    def __init__(self, data_val, data_size=0, data_type=-1):
        if isinstance(data_val, int) or data_type == Type.INT:
            self.i = data_val
            self.type = Type.INT
        elif isinstance(data_val, float):
            self.d = data_val
            self.type = Type.DOUBLE
        elif isinstance(data_val, basestring):
            self.s = data_val
            self.type = Type.STRING
        elif data_size > 0:
            self._b = Bytes(data_val, data_size)
            self.type = Type.BYTEARRAY
        else:
            self.u = data_val
            self.type = Type.UINT
            
    def __repr__(self):
        if (self.type == Type.BYTEARRAY):
            return self._b
        elif (self.type == Type.DOUBLE):
            return self.d
        elif (self.type == Type.INT):
            return self.i
        elif (self.type == Type.STRING):
            return self.s
        elif (self.type == Type.UINT):
            return self.u
            
    def __str__(self):
        if (self.type == Type.BYTEARRAY):
            return str(self._b)
        elif (self.type == Type.DOUBLE):
            return str(self.d)
        elif (self.type == Type.INT):
            return str(self.i)
        elif (self.type == Type.STRING):
            return self.s
        elif (self.type == Type.UINT):
            return str(self.u)
            
    def as_bytearray(self):
        return self._b
        
    def as_float(self):
        return self.d
        
    def as_int(self):
        return self.i
        
    def as_string(self):
        return self.s
        
    def as_uint(self):
        return self.u
        
    def is_bytearray(self):
        if (self.type == Type.BYTEARRAY): return True
        else: return False
        
    def is_float(self):
        if (self.type == Type.DOUBLE): return True
        else: return False
        
    def is_int(self):
        if (self.type == Type.INT): return True
        else: return False
        
    def is_string(self):
        if (self.type == Type.STRING): return True
        else: return False
        
    def is_uint(self):
        if (self.type == Type.UINT): return True
        else: return False


# def totimestamp(dt, epoch=datetime.datetime(1970,1,1)):
#     td = dt - epoch
#     # return td.total_seconds()
#     return (td.microseconds + (td.seconds + td.days * 86400) * 10**6) / 10**6

# Definition of Tag format
class Tag():
    @classmethod
    def __init__(self, value, at, unit):
        self._at = at
        self._unit = unit
        self._value = value

    def at(self):
        return self._at

    def unit(self):
        return self._unit

    def value(self):
        return self._value

# Time format
class Time():
    @classmethod
    def now(self):
        return int(time.mktime(datetime.datetime.now().timetuple()))


# re-organize tag format for fitting user defined callback function
def on_reorganize_tag_callback(callback):
    def warp_func(
            self, source_name, tag_name, data_value, data_type, data_unit,
            tag_ts):

        if callback is None:
            return

        if data_type == Type.UINT:
            val = data_value[0].u
        elif data_type == Type.INT:
            val = data_value[0].i
        elif data_type == Type.DOUBLE:
            val = data_value[0].d
        elif data_type == Type.STRING:
            val = data_value[0].s
        elif data_type == Type.BYTEARRAY:
            val = data_value[0]._b.b

        callback(source_name, tag_name, Tag(Value(val), tag_ts, data_unit))

    return warp_func


# PyTagAPI class
class TagV2():
    def __init__(self):
        # Indicate ctype to return value for avoiding 
        # access violation on x64 plaform 
        self._tag_new = _libmxtagf.mxtag_new
        _libmxtagf.mxtag_new.restype = c_void_p
        
        self._tag_publish = _libmxtagf.mxtag_publish
        _libmxtagf.mxtag_publish.restype = c_int
        _libmxtagf.mxtag_publish.argtypes = [c_void_p, c_char_p, c_char_p,
                                            POINTER(Value), c_int, c_char_p, c_int64]

        self._tag_subscribe = _libmxtagf.mxtag_subscribe
        _libmxtagf.mxtag_subscribe.restype = c_int
        _libmxtagf.mxtag_subscribe.argtypes = [c_void_p, c_char_p, c_char_p]

        self._tag_unsubscribe = _libmxtagf.mxtag_unsubscribe
        _libmxtagf.mxtag_unsubscribe.restype = c_int
        _libmxtagf.mxtag_unsubscribe.argtypes = [c_void_p, c_char_p, c_char_p]

        self._tag_subscribe_callback = _libmxtagf.mxtag_subscribe_callback
        _libmxtagf.mxtag_subscribe_callback.restype = c_int
        _libmxtagf.mxtag_subscribe_callback.argtypes = [c_void_p, c_void_p]
        
        self._instance = _libmxtagf.mxtag_new()
        self._callback = None

    @staticmethod
    def instance():
        return TagV2()

    def publish(self, source_name, tag_name, tag):
        # do publish
        return self._tag_publish(
            self._instance,
            source_name,
            tag_name,
            byref(tag.value()),
            tag.value().type,
            tag.unit(),
            tag.at()
        )

    def subscribe(self, source_name, tag_name):
        # do subscrbie
        return self._tag_subscribe(self._instance, source_name, tag_name)

    def unsubscribe(self, source_name, tag_name):
        # do unsubscribe
        return self._tag_unsubscribe(self._instance, source_name, tag_name)

    def subscribe_callback(self, on_tag_callback):
        # do subscribe callback
        on_tag_func = CFUNCTYPE(
            None, c_void_p, c_char_p, c_char_p, POINTER(Value), c_int,
            c_char_p, c_int64
        )

        # https://docs.python.org/2/library/ctypes.html
        # Must keep callback referenced otherwise gc may destroy it
        self._callback = on_tag_func(
            on_reorganize_tag_callback(on_tag_callback)
        )
        self._tag_subscribe_callback(self._instance, self._callback)