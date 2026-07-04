CLASS /eacm/cx_upload DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.

    DATA:
      mv_table_name  TYPE tabname READ-ONLY,
      mv_row_number  TYPE i READ-ONLY,
      mv_column_name TYPE string READ-ONLY,
      mv_detail      TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        previous  LIKE previous OPTIONAL
        iv_detail TYPE string OPTIONAL
        iv_table  TYPE tabname OPTIONAL
        iv_row    TYPE i OPTIONAL
        iv_column TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

ENDCLASS.



CLASS /EACM/CX_UPLOAD IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    mv_table_name  = iv_table.
    mv_row_number  = iv_row.
    mv_column_name = iv_column.
    mv_detail      = iv_detail.
  ENDMETHOD.


  METHOD get_text.
    result = COND #( WHEN mv_detail IS NOT INITIAL THEN mv_detail
                     ELSE super->get_text( ) ).
    IF mv_table_name IS NOT INITIAL.
      result = |{ result } [table={ mv_table_name }]|.
    ENDIF.
    IF mv_row_number IS NOT INITIAL.
      result = |{ result } [row={ mv_row_number }]|.
    ENDIF.
    IF mv_column_name IS NOT INITIAL.
      result = |{ result } [column={ mv_column_name }]|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
