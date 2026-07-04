CLASS /eacm/cl_table_directory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_table_info,
        table_name  TYPE tabname,
        description TYPE c LENGTH 60,
        category    TYPE c LENGTH 20,
        field_count TYPE i,
      END OF ts_table_info,
      tt_table_info TYPE STANDARD TABLE OF ts_table_info WITH EMPTY KEY.

    CLASS-METHODS list_tables
      IMPORTING iv_prefix        TYPE string OPTIONAL
      RETURNING VALUE(rt_result) TYPE tt_table_info.

  PRIVATE SECTION.
    CONSTANTS mc_namespace   TYPE string VALUE `/EACM/`.
    CONSTANTS mc_max_results TYPE i      VALUE 50.

    CLASS-METHODS enrich
      IMPORTING iv_table         TYPE tabname
      RETURNING VALUE(rs_result) TYPE ts_table_info.

    CLASS-METHODS normalize_input
      IMPORTING iv_prefix       TYPE string
      RETURNING VALUE(rv_input) TYPE string.

ENDCLASS.



CLASS /eacm/cl_table_directory IMPLEMENTATION.


  METHOD list_tables.
    DATA(lv_input) = normalize_input( iv_prefix ).

    TRY.
        DATA(lo_filter) = xco_cp_abap_repository=>object_name->get_filter(
                            xco_cp_abap_sql=>constraint->contains_pattern( |{ mc_namespace }%| ) ).
        DATA(lt_objects) = xco_cp_abap_repository=>objects->tabl->where( VALUE #( ( lo_filter ) )
                              )->in( xco_cp_abap=>repository )->get( ).

        DATA lt_names TYPE SORTED TABLE OF tabname WITH NON-UNIQUE KEY table_line.
        LOOP AT lt_objects INTO DATA(lo_object).
          INSERT lo_object->name INTO TABLE lt_names.
        ENDLOOP.

        DATA(lv_count) = 0.
        LOOP AT lt_names INTO DATA(lv_name).
          IF lv_count >= mc_max_results.
            EXIT.
          ENDIF.

          DATA(ls_info)     = enrich( lv_name ).
          DATA(lv_name_up)  = to_upper( CONV string( ls_info-table_name ) ).
          DATA(lv_descr_up) = to_upper( CONV string( ls_info-description ) ).

          IF lv_input IS INITIAL
             OR lv_name_up  CS lv_input
             OR lv_descr_up CS lv_input.
            APPEND ls_info TO rt_result.
            lv_count = lv_count + 1.
          ENDIF.
        ENDLOOP.
      CATCH cx_root.
        CLEAR rt_result.
    ENDTRY.
  ENDMETHOD.


  METHOD enrich.
    rs_result-table_name = iv_table.

    TRY.
        DATA(lo_table) = xco_cp_abap_dictionary=>database_table( CONV #( iv_table ) ).
        IF lo_table->exists( ).
          DATA(lo_content) = lo_table->content( ).
          rs_result-description = lo_content->get_short_description( ).
          rs_result-field_count = lines( lo_content->get_raw_fields( ) ).

          DATA(lv_delivery) = lo_content->get_delivery_class( )->value.
          rs_result-category = SWITCH #( lv_delivery
            WHEN 'C' THEN 'CUSTOMIZING'
            WHEN 'A' THEN 'MASTER'
            WHEN 'L' THEN 'TRANSACTIONAL'
            WHEN 'S' THEN 'SYSTEM'
            ELSE         'OTHER' ).
        ENDIF.
      CATCH cx_root INTO DATA(lo_cx).
        DATA(msg) = lo_cx->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD normalize_input.
    rv_input = to_upper( condense( iv_prefix ) ).
  ENDMETHOD.
ENDCLASS.
