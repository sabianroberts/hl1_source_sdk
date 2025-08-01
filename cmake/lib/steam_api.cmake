block()
	set( lib_name steam_api )
	set( lib_dir ${SOURCE_SDK_ROOT}/lib/public )

	add_library( ${lib_name} SHARED IMPORTED GLOBAL )

	if( WIN32 )
		if( SOURCE_SDK_MIN_STEAM_API )
			set( lib_file_name steam_api_min )
		else()
			set( lib_file_name steam_api )
		endif()

		set_property( TARGET ${lib_name} PROPERTY IMPORTED_IMPLIB ${lib_dir}/${lib_file_name}.lib )
	elseif( APPLE )
		set_property( TARGET ${lib_name} PROPERTY IMPORTED_LOCATION ${lib_dir}/lib${lib_name}.dylib )
	else()
		set_property( TARGET ${lib_name} PROPERTY IMPORTED_LOCATION ${lib_dir}/lib${lib_name}.so )
	endif()
endblock()
