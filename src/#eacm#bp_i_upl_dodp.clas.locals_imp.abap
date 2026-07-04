CLASS lhc_/eacm/i_upl_dodp DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR /eacm/iUplDodp
        RESULT result,
      uploadFileData FOR MODIFY
        IMPORTING keys FOR ACTION /eacm/iUplDodp~uploadFileData RESULT result.

    METHODS FillFileStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR /eacm/iUplDodp~FillFileStatus.

    METHODS FillSelectedStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR /eacm/iUplDodp~FillSelectedStatus.
*    METHODS lock FOR LOCK
*      IMPORTING keys FOR LOCK /eacm/iUplDodp.

*    METHODS ProcessDO CHANGING i_zprdo TYPE /eacm/prdo.
*    METHODS ProcessDP CHANGING  i_zprdp        TYPE /eacm/zprdp
*                      RETURNING VALUE(r_error) TYPE abap_boolean.
*
*    CLASS-METHODS persist
*      IMPORTING i_data            TYPE ANY TABLE
*                i_table           TYPE tabname
*                i_dele            TYPE abap_boolean
*      RETURNING VALUE(r_inserted) TYPE i.
*    METHODS setFinalStatus FOR DETERMINE ON SAVE
*      IMPORTING keys FOR /eacm/iUplDodp~setFinalStatus.

ENDCLASS.

CLASS lhc_/eacm/i_upl_dodp IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD uploadFileData.

    "lettura del record
    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
    ENTITY /eacm/iUplDodp
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_file_entity).

    READ TABLE lt_file_entity INDEX 1 INTO DATA(ls_file_entity).

    "verifica compilazione tabella
    IF ls_file_entity-Dodp <> 'ZPRDO' AND ls_file_entity-Dodp <> 'ZPRDP'.
      APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
      APPEND VALUE #(
        %tky =  ls_file_entity-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Enter table value'
                   )
      ) TO reported-/eacm/iupldodp.
      RETURN.
    ENDIF.

    "lettura dell'allegato
    DATA(lv_attachment) = ls_file_entity-Attachment.
    IF lv_attachment IS INITIAL.
      APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
      APPEND VALUE #(
        %tky =  ls_file_entity-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Empty file'
                   )
      ) TO reported-/eacm/iupldodp.
      RETURN.
    ENDIF.

    "Conversione allegato in formato stringa
    TRY.
*        DATA(lv_content) = cl_abap_conv_codepage=>create_in( )->convert( lv_attachment ).
        DATA(lv_content) = cl_abap_conv_codepage=>create_in( codepage = 'WINDOWS-1252' )->convert( lv_attachment ).
      CATCH cx_sy_conversion_codepage INTO DATA(ex).
        APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
        APPEND VALUE #(
          %tky =  ls_file_entity-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = 'Conversion error'
                     )
        ) TO reported-/eacm/iupldodp.
        RETURN.
    ENDTRY.

    IF lv_content IS INITIAL.
      APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
      APPEND VALUE #(
        %tky =  ls_file_entity-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Empty file'
                   )
      ) TO reported-/eacm/iupldodp.
      RETURN.
    ENDIF.
*****
*****    "Numero di colonne della tabella su DB
*****    FIELD-SYMBOLS <tb> TYPE ANY TABLE.
*****    FIELD-SYMBOLS <ln> TYPE any.
*****    DATA lt_zprdo TYPE STANDARD TABLE OF /eacm/prdo.
*****    DATA lt_zprdp TYPE STANDARD TABLE OF /EACM/ZPRDp.
*****    DATA ls_zprdo TYPE /eacm/prdo.
*****    DATA ls_zprdp TYPE /EACM/ZPRDp.
*****    IF ls_file_entity-Dodp = 'ZPRDO'.
*****      ASSIGN lt_zprdo TO <tb>.
*****      ASSIGN ls_zprdo TO <ln>.
*****    ELSE.
*****      ASSIGN lt_zprdp TO <tb>.
*****      ASSIGN ls_zprdp TO <ln>.
*****    ENDIF.
*****    DATA lo_table_descr  TYPE REF TO cl_abap_tabledescr.
*****    DATA lo_line_descr   TYPE REF TO cl_abap_structdescr.
*****    lo_table_descr ?= cl_abap_typedescr=>describe_by_data( <tb> ).
*****    lo_line_descr  ?= lo_table_descr->get_table_line_type( ).
*****
*****    "valorizzazione tabella con i sinngoli record
*****    SPLIT lv_content AT cl_abap_char_utilities=>cr_lf INTO TABLE DATA(lt_lines).
*****
*****
*****
*****    "esamina dei records
*****    LOOP AT lt_lines INTO DATA(ls_line).
*****      DATA(lv_tabix) = sy-tabix.
*****
*****      "Campi tabelle
*****      SPLIT ls_line AT cl_abap_char_utilities=>horizontal_tab INTO TABLE DATA(lt_fields).
*****
******      IF lv_tabix = 1.
******        "verifica tracciato idetico tra file e tabella db
******        IF lines( lt_fields ) <> lines( lo_line_descr->components ).
******          APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
******          APPEND VALUE #(
******            %tky =  ls_file_entity-%tky
******                %msg = new_message_with_text(
******                         severity = if_abap_behv_message=>severity-error
******                         text     = 'Wrong structure'
******                       )
******          ) TO reported-/eacm/iupldodp.
******          RETURN.
******        ENDIF.
******      ENDIF.
*****
*****      CLEAR ls_zprdo.
*****      DATA lv_vbeln TYPE vbeln.
*****      LOOP AT lt_fields INTO DATA(ls_fields).
*****        lv_tabix = sy-tabix. "se va in errore nel loop non perdo il puntamento alla colonna
*****        ASSIGN COMPONENT lv_tabix OF STRUCTURE <ln> TO FIELD-SYMBOL(<f>).
*****        CHECK sy-subrc = 0.
*****        DATA lo_type_descriptor TYPE REF TO cl_abap_typedescr.
*****        lo_type_descriptor ?= cl_abap_datadescr=>describe_by_data( <f> ).
*****        CASE lo_type_descriptor->type_kind.
*****          WHEN 'D'.          " Data
******            <f> = ls_fields.
*****            IF strlen( ls_fields ) = 10.
*****              <f> = ls_fields+6 && ls_fields+3(2) && ls_fields(2).
*****            ENDIF.
*****          WHEN 'P'.
*****            REPLACE ALL OCCURRENCES OF '.' IN ls_fields WITH space.
*****            REPLACE ',' IN ls_fields WITH '.'.
*****            <f> = ls_fields.
*****          WHEN OTHERS.
*****            <f> = ls_fields.
*****        ENDCASE.
*****        IF lo_type_descriptor->absolute_name+6(5) = 'VBELN' AND lv_tabix = 5.
*****          lv_vbeln = <f>.
*****        ENDIF.
*****
*****      ENDLOOP.
*****
*****      IF ls_file_entity-Dodp = 'ZPRDO'.
*****        "Verifiche e modifiche ZPRDO
*****        processdo(
*****          CHANGING
*****            i_zprdo = <ln>
*****        ).
*****      ELSE.
*****        "Verifiche e modifiche ZPRDO
*****        IF processdp( CHANGING i_zprdp = <ln> ) = abap_true.
*****          APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
*****          APPEND VALUE #(
*****            %tky =  ls_file_entity-%tky
*****                %msg = new_message_with_text(
*****                         severity = if_abap_behv_message=>severity-error
*****                         text     = |'ZPRDO not found for '{ lv_vbeln }|
*****                       )
*****          ) TO reported-/eacm/iupldodp.
******          RETURN.
*****        ENDIF.
*****        .
*****      ENDIF.
*****      INSERT <ln> INTO TABLE <tb>.
*****
*****    ENDLOOP.
*****
*****    "Salvataggio dati
*****    IF ls_file_entity-TestMode = abap_false.
*****
*****      gv_delete = ls_file_entity-Tbdel.
*****      IF ls_file_entity-Dodp = 'ZPRDO'.
*****        gt_zprdo = <tb>.
*****      ELSE.
*****        gt_zprdp = <tb>.
*****      ENDIF.
*****
******      DATA(lv_inserted) = /eacm/cl_upl_dodp=>persist(
******         EXPORTING
******           i_data      = <tb>
******           i_table     = CONV #( ls_file_entity-Dodp )
******           i_dele      = ls_file_entity-Tbdel
******       ).
*****
******      IF ls_file_entity-Dodp = 'ZPRDO'.
******        IF ls_file_entity-Tbdel = abap_true.
******          DELETE FROM /eacm/prdo.
******        ENDIF.
******        INSERT /eacm/prdo FROM TABLE @<tb>.
******      ELSE.
******        IF ls_file_entity-Tbdel = abap_true.
******          DELETE FROM /eacm/zprdp.
******        ENDIF.
******        INSERT /eacm/zprdp FROM TABLE @<tb>.
******      ENDIF.
*****    ENDIF.

**      DATA(ls_res) = /eacm/cl_table_uploader=>upload(
**        VALUE #(
**          table        = CONV tabname( <ls_key>-%param-target_table )
**          file_name    = CONV string( <ls_key>-%param-file_name )
**          file_type    = CONV string( <ls_key>-%param-file_type )
**          file_content = lv_content_x
**          mode         = CONV string( <ls_key>-%param-upload_mode )
**          transport    = <ls_key>-%param-transport ) ).
*    "cancella dati esistenti
*    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*    ENTITY /eacm/iUplDodp
*    ALL FIELDS WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_existing_Data).
*    IF lt_existing_Data IS NOT INITIAL.
*      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*      ENTITY /eacm/iUplDodp DELETE FROM VALUE #(
*        FOR ls_data IN lt_existing_Data (
*         %key = ls_data-%key
*         %is_draft = ls_data-%is_draft
*        )
*      )
*      MAPPED DATA(lt_del_mapped)
*      REPORTED DATA(lt_del_reported)
*      FAILED DATA(lt_del_failed).
*    ENDIF.

    "modifica stato
*    MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*    ENTITY /eacm/iUplDodp
*    UPDATE FROM VALUE #( (
*        %tky = lt_file_entity[ 1 ]-%tky
*        FileStatus = 'File Uploaded'
*        %control-FileStatus = if_abap_behv=>mk-on ) )
*    MAPPED DATA(lt_upd_mapped)
*    REPORTED DATA(lt_upd_reported)
*    FAILED DATA(lt_upd_failed).
    MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
      ENTITY /eacm/iUplDodp
      UPDATE FIELDS ( FileStatus Attachment Dodp Tbdel )
      WITH VALUE #(
        FOR key IN keys
        ( %tky          = key-%tky
          FileStatus        = 'File Uploaded'
          Attachment = ls_file_entity-Attachment
          Dodp = ls_file_entity-Dodp
          Tbdel = ls_file_entity-Tbdel
 ) ).

    "leggi entry aggiornata
    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
    ENTITY /eacm/iUplDodp ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_updated_header).

    "Invio stato al front end
    result = VALUE #(
        FOR ls_upd_head IN lt_updated_header (
          %tky = ls_upd_head-%tky
          %param = ls_upd_head
        )
    ).
  ENDMETHOD.

  METHOD FillFileStatus.
    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
    ENTITY /eacm/iUplDodp FIELDS ( EndUser FileID TestMode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_files).

    LOOP AT lt_files INTO DATA(ls_files).
      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
      ENTITY /eacm/iUplDodp
      UPDATE FIELDS ( FileStatus TestMode EndUser )
      WITH VALUE #( ( %tky = ls_files-%tky
      %data-FileStatus = 'File not selected'
      %data-TestMode = 'X'
      %data-EndUser = cl_abap_context_info=>get_user_technical_name( )
      %control-FileStatus = if_abap_behv=>mk-on
      %control-TestMode = if_abap_behv=>mk-on
      %control-EndUser = if_abap_behv=>mk-on
      ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD FillSelectedStatus.
    "cancella dati esistenti
    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
    ENTITY /eacm/iUplDodp
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_existing).

    IF lt_existing IS NOT INITIAL.
      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
      ENTITY /eacm/iUplDodp DELETE FROM VALUE #(
      FOR ls_data IN lt_existing (
        %key = ls_data-%key
*        %is_draft = ls_data-%is_draft
        ) ).
    ENDIF.

    "leggo i dati e cambio stato
    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
    ENTITY /eacm/iUplDodp ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_head).

    LOOP AT lt_head INTO DATA(ls_head).
      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
      ENTITY /eacm/iUplDodp
      UPDATE FIELDS ( FileStatus )
      WITH VALUE #( (
      %tky =  ls_head-%tky
      %data-FileStatus = COND #(
          WHEN ls_head-Attachment IS INITIAL
          THEN 'File not selected'
          ELSE 'File selected' )
          %control-FileStatus = if_abap_behv=>mk-on
      ) ).

    ENDLOOP.
  ENDMETHOD.



*  METHOD persist.
**    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
**    ASSIGN i_data->* TO <lt_data>.
*    DATA(v_table) = '/EACM/' && i_table.
*
*    TRY.
*        IF i_dele = abap_true.
*          DELETE FROM (v_table).
*        ENDIF.
*        INSERT (v_table) FROM TABLE @i_data.
*      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
*        r_inserted = 0.
**        RAISE EXCEPTION NEW /eacm/cx_upload( previous  = lx_sql
**                                             iv_table  = i_table
**                                             iv_detail = |DB error: { lx_sql->get_text( ) }| ).
*    ENDTRY.
*
*  ENDMETHOD.

*  METHOD setfinalstatus.
**    DATA lt_update TYPE TABLE FOR UPDATE zi_order\\Order.
**
*    " Leggo i dati correnti dal transactional buffer
*    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*      ENTITY /eacm/iUplDodp
*      ALL FIELDS WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_head).
*
*    LOOP AT lt_head INTO DATA(ls_head).
*      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*      ENTITY /eacm/iUplDodp
*      UPDATE FIELDS ( FileStatus )
*      WITH VALUE #( (
*      %tky =  ls_head-%tky
*      %data-FileStatus = 'File saved'
*          %control-FileStatus = if_abap_behv=>mk-on
*      ) ).
*
*    ENDLOOP.
**
***    IF lt_update IS NOT INITIAL.
**      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
**        ENTITY /eacm/iUplDodp
**        UPDATE FIELDS ( FinalStatus Status )
**        WITH lt_update
**        FAILED   DATA(failed_det)
**        REPORTED DATA(reported_det).
***    ENDIF.
*  ENDMETHOD.

ENDCLASS.

CLASS lsc_/eacm/i_upl_dodp DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.
    METHODS ProcessDO CHANGING i_zprdo TYPE /eacm/prdo.
    METHODS ProcessDP CHANGING  i_zprdp        TYPE /eacm/zprdp
                      RETURNING VALUE(r_error) TYPE abap_boolean.
*
*    CLASS-METHODS persist
*      IMPORTING i_data            TYPE ANY TABLE
*                i_table           TYPE tabname
*                i_dele            TYPE abap_boolean
*      RETURNING VALUE(r_inserted) TYPE i.
ENDCLASS.

CLASS lsc_/eacm/i_upl_dodp IMPLEMENTATION.

  METHOD save_modified.
    READ TABLE create-/eacm/iupldodp INTO DATA(ls_file) INDEX 1.
    IF sy-subrc <> 0.
      READ TABLE update-/eacm/iupldodp INTO ls_file INDEX 1.
      IF sy-subrc <> 0 .
        RETURN.
      ENDIF.
    ENDIF.

    IF ls_file-TestMode = abap_true.
      RETURN.
    ENDIF.


    "lettura dell'allegato
    DATA(lv_attachment) = ls_file-Attachment.

    IF lv_attachment IS INITIAL.
      RETURN.
    ENDIF.

    "Conversione allegato in formato stringa
    TRY.
*        DATA(lv_content) = cl_abap_conv_codepage=>create_in( )->convert( lv_attachment ).
        DATA(lv_content) = cl_abap_conv_codepage=>create_in( codepage = 'WINDOWS-1252' )->convert( lv_attachment ).
      CATCH cx_sy_conversion_codepage INTO DATA(ex).
        RETURN.
    ENDTRY.

    "Numero di colonne della tabella su DB
    FIELD-SYMBOLS <tb> TYPE ANY TABLE.
    FIELD-SYMBOLS <ln> TYPE any.
    DATA lt_zprdo TYPE STANDARD TABLE OF /eacm/prdo.
    DATA lt_zprdp TYPE STANDARD TABLE OF /EACM/ZPRDp.
    DATA ls_zprdo TYPE /eacm/prdo.
    DATA ls_zprdp TYPE /EACM/ZPRDp.
    IF ls_file-Dodp = 'ZPRDO'.
      ASSIGN lt_zprdo TO <tb>.
      ASSIGN ls_zprdo TO <ln>.
    ELSE.
      ASSIGN lt_zprdp TO <tb>.
      ASSIGN ls_zprdp TO <ln>.
    ENDIF.
    DATA lo_table_descr  TYPE REF TO cl_abap_tabledescr.
    DATA lo_line_descr   TYPE REF TO cl_abap_structdescr.
    lo_table_descr ?= cl_abap_typedescr=>describe_by_data( <tb> ).
    lo_line_descr  ?= lo_table_descr->get_table_line_type( ).

    "valorizzazione tabella con i sinngoli record
    SPLIT lv_content AT cl_abap_char_utilities=>cr_lf INTO TABLE DATA(lt_lines).

    "esamina dei records
    LOOP AT lt_lines INTO DATA(ls_line).
      DATA(lv_tabix) = sy-tabix.

      "Campi tabelle
      SPLIT ls_line AT cl_abap_char_utilities=>horizontal_tab INTO TABLE DATA(lt_fields).

*      IF lv_tabix = 1.
*        "verifica tracciato idetico tra file e tabella db
*        IF lines( lt_fields ) <> lines( lo_line_descr->components ).
**          APPEND VALUE #( %tky = ls_file_entity-%tky ) TO failed-/eacm/iupldodp.
**          APPEND VALUE #(
**            %tky =  ls_file_entity-%tky
**                %msg = new_message_with_text(
**                         severity = if_abap_behv_message=>severity-error
**                         text     = 'Wrong structure'
**                       )
**          ) TO reported-/eacm/iupldodp.
*          RETURN.
*        ENDIF.
*      ENDIF.

      CLEAR ls_zprdo.
      DATA lv_vbeln TYPE vbeln.
      LOOP AT lt_fields INTO DATA(ls_fields).
        lv_tabix = sy-tabix. "se va in errore nel loop non perdo il puntamento alla colonna
        ASSIGN COMPONENT lv_tabix OF STRUCTURE <ln> TO FIELD-SYMBOL(<f>).
        CHECK sy-subrc = 0.
        DATA lo_type_descriptor TYPE REF TO cl_abap_typedescr.
        lo_type_descriptor ?= cl_abap_datadescr=>describe_by_data( <f> ).
        CASE lo_type_descriptor->type_kind.
          WHEN 'D'.          " Data
*            <f> = ls_fields.
            IF strlen( ls_fields ) = 10.
              <f> = ls_fields+6 && ls_fields+3(2) && ls_fields(2).
            ENDIF.
          WHEN 'P'.
            REPLACE ALL OCCURRENCES OF '.' IN ls_fields WITH space.
            REPLACE ',' IN ls_fields WITH '.'.
            <f> = ls_fields.
          WHEN OTHERS.
            <f> = ls_fields.
        ENDCASE.
        IF lo_type_descriptor->absolute_name+6(5) = 'VBELN' AND lv_tabix = 5.
          lv_vbeln = <f>.
        ENDIF.

      ENDLOOP.

      IF ls_file-Dodp = 'ZPRDO'.
        "Verifiche e modifiche ZPRDO
        processdo(
          CHANGING
            i_zprdo = <ln>
        ).
      ELSE.
        "Verifiche e modifiche ZPRDO
        IF processdp( CHANGING i_zprdp = <ln> ) = abap_true.
          CONTINUE.
        ENDIF.
        .
      ENDIF.
      INSERT <ln> INTO TABLE <tb>.

    ENDLOOP.
*****
*****    "Salvataggio dati
*****    IF ls_file_entity-TestMode = abap_false.
*****
*****      gv_delete = ls_file_entity-Tbdel.
*****      IF ls_file_entity-Dodp = 'ZPRDO'.
*****        gt_zprdo = <tb>.
*****      ELSE.
*****        gt_zprdp = <tb>.
*****      ENDIF.
*****
******      DATA(lv_inserted) = /eacm/cl_upl_dodp=>persist(
******         EXPORTING
******           i_data      = <tb>
******           i_table     = CONV #( ls_file_entity-Dodp )
******           i_dele      = ls_file_entity-Tbdel
******       ).
*****
    IF ls_file-Dodp = 'ZPRDO'.
      IF ls_file-Tbdel = abap_true.
        DELETE FROM /eacm/prdo.                         "#EC CI_NOWHERE
      ENDIF.
      TRY.
          INSERT /eacm/prdo FROM TABLE @<tb>.
        CATCH cx_root INTO DATA(lo_cx).
          DATA(msg) = lo_cx->get_text( ).
      ENDTRY.
    ELSE.
      IF ls_file-Tbdel = abap_true.
        DELETE FROM /eacm/zprdp.                        "#EC CI_NOWHERE
      ENDIF.
      TRY.
          INSERT /eacm/zprdp FROM TABLE @<tb>.
        CATCH cx_root INTO lo_cx.
          msg = lo_cx->get_text( ).
      ENDTRY.
    ENDIF.
**********************************************************************
*    ls_file-FileStatus = 'Saved'.
*      MODIFY ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*      ENTITY /eacm/iUplDodp
*      UPDATE FIELDS ( FileStatus )
*      WITH VALUE #( (
*      %key =  ls_file-%key
*      %data-FileStatus = 'Saved' )
*      ) .

*    "leggi entry aggiornata
*    READ ENTITIES OF /eacm/i_upl_dodp IN LOCAL MODE
*    ENTITY /eacm/iUplDodp ALL FIELDS WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_updated_header).

    "Invio stato al front end
*    result = VALUE #(
*          FOR ls_result IN lt_result
*          ( %tky = ls_result-%tky
*            %param = ls_result ) ).
  ENDMETHOD.

  METHOD ProcessDO.
    TYPES BEGIN OF tp_tblart.
    TYPES blart_old TYPE blart.
    TYPES blart_new TYPE blart.
    TYPES END OF tp_tblart.
    DATA lt_tblart TYPE STANDARD TABLE OF tp_tblart.
    lt_tblart = VALUE #(
        ( blart_old = 'AB' blart_new = 'DU' )
        ( blart_old = 'AS' blart_new = 'XX' )
        ( blart_old = 'AU' blart_new = 'DU' )
        ( blart_old = 'C1' blart_new = 'DA' )
        ( blart_old = 'C2' blart_new = 'DA' )
        ( blart_old = 'D1' blart_new = 'SW' )
        ( blart_old = 'D2' blart_new = 'SW' )
        ( blart_old = 'D3' blart_new = 'SW' )
        ( blart_old = 'DN' blart_new = 'DZ' )
        ( blart_old = 'DU' blart_new = 'DU' )
        ( blart_old = 'DW' blart_new = 'DZ' )
        ( blart_old = 'KL' blart_new = 'DZ' )
        ( blart_old = 'RG' blart_new = 'RG' )
        ( blart_old = 'RV' blart_new = 'RV' )
        ( blart_old = 'ZD' blart_new = 'ZD' )
    ).


    IF i_zprdo-zclpr <> 'SB'  OR " Provv.Manuali
       i_zprdo-ztprv = 'FATT' OR " Provv.SB su Fatturato
       i_zprdo-zcanv = 'NOCN' OR " Provv.SB Senza BKPF
       i_zprdo-zcanv = 'RTC'  OR " Provv.SB su Incassato
                                      "     Rata  Chiusa senza RIBA
       i_zprdo-zcanv = 'RBC1' OR " Provv.SB su Incassato
                                      "     RIBA  Chiusa da + di 1 mese
       i_zprdo-zcanv = 'INC'.

*      i_zprdo-zimiidd = i_zprdo-zimii.
    ELSE.

      DATA(lv_bktxt) = | { i_zprdo-belnr }'-'{ i_zprdo-gjahr }'%'|.
      SELECT SINGLE FROM /eacm/prdo "bkpf  DA SISTEMARE
      FIELDS belnr, gjahr
      WHERE bukrs =  @i_zprdo-bukrs
*AND bstat = space   " Fa parte del'indice
       AND blart = 'ZD'
* AND bktxt LIKE @lv_bktxt.
       AND maktx LIKE @lv_bktxt "DA SISTEMARE
       INTO @DATA(ls_bkpf).
      IF sy-subrc = 0.
        i_zprdo-belnr = ls_bkpf-belnr.
        i_zprdo-gjahr = ls_bkpf-gjahr.
      ENDIF.

      TRY.
          i_zprdo-blart = lt_tblart[ blart_old = i_zprdo-blart ]-blart_new.
        CATCH cx_sy_itab_line_not_found INTO DATA(lo_cx).
          DATA(msg) = lo_cx->get_text( ).
      ENDTRY.


    ENDIF.

    i_zprdo-zimiidd = i_zprdo-zimii.  "eOne - incassato
    i_zprdo-vtweg = '01'.

  ENDMETHOD.

  METHOD processdp.
    CLEAR r_error.

    i_zprdp-zwaersp = i_zprdp-waerk.  "Valuta di stampa facsimile
    i_zprdp-zkurrfp = 1.              "Cambio valuta di stampa
    i_zprdp-ziprvsf = i_zprdp-ziprv.  "Importo provvigione di stampa fac-simile
    i_zprdp-ziprvvs = i_zprdp-ziprv.  "Importo provvigione in valuta società
    i_zprdp-zimansf = i_zprdp-ziman.  "Importo anticipo di stampa fac-simile
    i_zprdp-zimaosf = i_zprdp-zimao.  "Importo anticipo originario di stampa fac-simile
    i_zprdp-zirecsf = i_zprdp-zirec.  "Importo recuperato in valuta fac-simile

    SELECT SINGLE FROM /eacm/prdo
    FIELDS belnr, blart, gjahr, zlord, zimco
    WHERE vkorg = @i_zprdp-vkorg
    AND vtweg = @i_zprdp-vtweg
    AND zclpr = @i_zprdp-zclpr
    AND vbeln = @i_zprdp-vbeln
    AND posnr = @i_zprdp-posnr
    AND zcdaz = @i_zprdp-zcdaz
    AND zidag = @i_zprdp-zidag
    INTO @DATA(ls_zprdo).
    IF sy-subrc <> 0.
      r_error = abap_true.
      RETURN.
    ENDIF.

    i_zprdp-belnr = ls_zprdo-belnr.
    i_zprdp-gjahr = ls_zprdo-gjahr.
*{    eOne - incassato
    "importo fattura : totale provvigioni = incasso fattura : importo della provvigione
    "ZLORD : ZIMCO = ZZINC : ZIPRV
    IF ls_zprdo-zimco IS NOT INITIAL.
      i_zprdp-zinc = ls_zprdo-zlord * i_zprdp-ziprv / ls_zprdo-zimco.
    ENDIF.  "}

  ENDMETHOD.

ENDCLASS.
