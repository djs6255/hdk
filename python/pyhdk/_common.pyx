#
# Copyright 2022 Intel Corporation.
#
# SPDX-License-Identifier: Apache-2.0

from libcpp.memory cimport unique_ptr, make_unique, shared_ptr
from cython.operator cimport dereference

cdef class SQLType:
  cdef CSQLTypes c_val

  def __cinit__(self, int val):
    self.c_val = <CSQLTypes>val

  def __eq__(self, val):
    if isinstance(val, int):
      return <int>self.c_val == val
    if isinstance(val, str):
      return self.__repr__() == val
    if isinstance(val, SQLType):
      return <int>self.c_val == <int>val.c_val
    return False

  def __repr__(self):
    cdef names = {
      <int>kNULLT : "NULLT",
      <int>kBOOLEAN : "BOOLEAN",
      <int>kCHAR : "CHAR",
      <int>kVARCHAR : "VARCHAR",
      <int>kNUMERIC : "NUMERIC",
      <int>kDECIMAL : "DECIMAL",
      <int>kINT : "INT",
      <int>kSMALLINT : "SMALLINT",
      <int>kFLOAT : "FLOAT",
      <int>kDOUBLE : "DOUBLE",
      <int>kTIME : "TIME",
      <int>kTIMESTAMP : "TIMESTAMP",
      <int>kBIGINT : "BIGINT",
      <int>kTEXT : "TEXT",
      <int>kDATE : "DATE",
      <int>kARRAY : "ARRAY",
      <int>kINTERVAL_DAY_TIME : "INTERVAL_DAY_TIME",
      <int>kINTERVAL_YEAR_MONTH : "INTERVAL_YEAR_MONTH",
      <int>kTINYINT : "TINYINT",
      <int>kEVAL_CONTEXT_TYPE : "EVAL_CONTEXT_TYPE",
      <int>kVOID : "VOID",
      <int>kCURSOR : "CURSOR",
      <int>kCOLUMN : "COLUMN",
      <int>kCOLUMN_LIST : "COLUMN_LIST",
      <int>kSQLTYPE_LAST : "LAST",
    }
    return names[<int>self.c_val]

cdef class TypeInfo:
  @property
  def type(self):
    return SQLType(self.c_type_info.get_type())

  @property
  def subtype(self):
    return SQLType(self.c_type_info.get_subtype())

  @property
  def dimension(self):
    return self.c_type_info.get_dimension()

  @property
  def precision(self):
    return self.c_type_info.get_precision()

  @property
  def input_srid(self):
    return self.c_type_info.get_input_srid()

  @property
  def scale(self):
    return self.c_type_info.get_scale()

  @property
  def output_srid(self):
    return self.c_type_info.get_output_srid()

  @property
  def notnull(self):
    return self.c_type_info.get_notnull()

  @property
  def compression(self):
    return self.c_type_info.get_compression()

  @property
  def comp_param(self):
    return self.c_type_info.get_comp_param()

  @property
  def size(self):
    return self.c_type_info.get_size()

  @property
  def logical_size(self):
    return self.c_type_info.get_logical_size()

  def __str__(self):
    return self.c_type_info.toString()

  def __repr__(self):
    return self.c_type_info.toString()

def buildConfig(*, enable_debug_timer=None, enable_union=False, **kwargs):
  global g_enable_debug_timer
  if enable_debug_timer is not None:
    g_enable_debug_timer = enable_debug_timer

  # Remove legacy params to provide better compatibility with PyOmniSciDbe
  kwargs.pop("enable_union", None)
  kwargs.pop("enable_thrift_logs", None)

  cmd_str = "".join(' --%s %r' % arg for arg in kwargs.iteritems())
  cmd_str = cmd_str.replace("_", "-")
  cdef string app = "modin".encode('UTF-8')
  cdef CConfigBuilder builder
  builder.parseCommandLineArgs(app, cmd_str, False)
  cdef Config config = Config()
  config.c_config = builder.config()
  return config

def initLogger(*, debug_logs=False, **kwargs):
  argv0 = "PyHDK".encode('UTF-8')
  cdef char *cargv0 = argv0
  cdef unique_ptr[CLogOptions] opts = make_unique[CLogOptions](cargv0)
  if debug_logs:
    opts.get().severity_ = CSeverity.DEBUG3
  CInitLogger(dereference(opts))
