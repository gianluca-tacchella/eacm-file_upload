INTERFACE /eacm/if_file_parser
  PUBLIC.

  TYPES:
    ty_row    TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
    ty_matrix TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.

  METHODS parse
    IMPORTING iv_content     TYPE xstring
    RETURNING VALUE(rt_rows) TYPE ty_matrix
    RAISING   /eacm/cx_upload.

ENDINTERFACE.
