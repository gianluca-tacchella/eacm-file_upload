CLASS /eacm/cl_parser_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF mc_type,
        xlsx TYPE string VALUE `XLSX`,
        csv  TYPE string VALUE `CSV`,
      END OF mc_type.

    CLASS-METHODS create
      IMPORTING iv_type          TYPE string
      RETURNING VALUE(ro_parser) TYPE REF TO /eacm/if_file_parser
      RAISING   /eacm/cx_upload.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS /EACM/CL_PARSER_FACTORY IMPLEMENTATION.


  METHOD create.
    DATA(lv_type) = to_upper( iv_type ).
    CASE lv_type.
      WHEN mc_type-xlsx.
        ro_parser = NEW /eacm/cl_parser_xlsx( ).
      WHEN mc_type-csv.
        ro_parser = NEW /eacm/cl_parser_csv( ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW /eacm/cx_upload(
          iv_detail = |Unsupported file type: { iv_type }. Use XLSX or CSV.| ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
