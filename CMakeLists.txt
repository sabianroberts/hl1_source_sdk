cmake_minimum_required( VERSION 3.25.0 )

project( hl1_source_sdk )

set( CMAKE_FOLDER "Source SDK" )
set( SOURCE_SDK_ROOT ${CMAKE_CURRENT_SOURCE_DIR} )

# DLL extension macro
if( WIN32 )
	set( DLL_EXT_MACRO ".dll" )
elseif( APPLE )
	set( DLL_EXT_MACRO ".dylib" )
else()
	set( DLL_EXT_MACRO ".so" )
endif()

# Platform definitions
if( UNIX )
	set( PLATFORM_DEFINES
		GNUC
		POSIX
	)

	if( APPLE )
		set( PLATFORM_DEFINES
			${PLATFORM_DEFINES}
			OSX
		)
	else()
		set( PLATFORM_DEFINES
			${PLATFORM_DEFINES}
			LINUX
			_LINUX
		)
	endif()
endif()

# Windows XP support - disables thread-safe init
macro( source_sdk_check_winxp_support target_name )
	# Visual Studio only.
	if( MSVC )
		#Verify that we have the data we need.
		if( NOT TARGET ${target_name} )
			message( FATAL_ERROR "Target ${target_name} does not exist" )
		endif()

		# VS2015 and newer requires this
		if( NOT "${MSVC_VERSION}" LESS 1900 AND CMAKE_VS_PLATFORM_TOOLSET MATCHES ".*_xp$" )
			get_target_property( FLAGS ${target_name} COMPILE_FLAGS )
			
			# Check if it's already set. Eliminates some noise in the output if it was explicitly disabled before
			if( ${FLAGS} STREQUAL "NOTFOUND" )
				message( WARNING "Couldn't get compile flags from target ${target_name}" )
			else()
				if( NOT FLAGS MATCHES "/Zc:threadSafeInit-" )
					target_compile_options( ${target_name} PRIVATE
						/Zc:threadSafeInit-
					)
				endif()
			endif()
		endif()
	endif()
endmacro()

# gfx path (path to 800corner*.tga in game directory)
if( NOT SOURCE_SDK_GFX_PATH )
	set( SOURCE_SDK_GFX_PATH "gfx/vgui2" )
endif()

# Steam API
if( NOT WIN32 )
	# SOURCE_SDK_MIN_STEAM_API is Windows-only
	set( SOURCE_SDK_MIN_STEAM_API FALSE )
endif()

if( SOURCE_SDK_NO_STEAM )
	set( STEAM_API_DEFINES
		NO_STEAM
	)
else()
	include( cmake/lib/steam_api.cmake )

	set( STEAM_API_LIBRARIES
		steam_api
	)

	# Links client with a steam_api.dll with less symbols.
	# Allows client.dll run on HL with old engine (but SteamAPI won't work).
	if( SOURCE_SDK_MIN_STEAM_API )
		set( STEAM_API_DEFINES
			SOURCE_SDK_MIN_STEAM_API
		)
	endif()
endif()

set( SOURCE_SDK_DEFINES
	${SOURCE_SDK_DEFINES}
	${PLATFORM_DEFINES}
	${STEAM_API_DEFINES}
	NO_MALLOC_OVERRIDE
	MATHLIB_HEADER_ONLY
	_DLL_EXT=${DLL_EXT_MACRO}
	SOURCE_SDK_GFX_PATH="${SOURCE_SDK_GFX_PATH}"
)

if( SOURCE_SDK_VGUI_NS_ALIAS )
	# `namespace vgui = vgui2` for compatibility with large parts of Source SDK
	set( SOURCE_SDK_DEFINES
		${SOURCE_SDK_DEFINES}
		SOURCE_SDK_VGUI_NS_ALIAS
	)
endif()

set( SOURCE_SDK_INCLUDE_PATHS
	${SOURCE_SDK_INCLUDE_PATHS}
	${CMAKE_CURRENT_SOURCE_DIR}/common
	${CMAKE_CURRENT_SOURCE_DIR}/public
	${CMAKE_CURRENT_SOURCE_DIR}/public/tier0
	${CMAKE_CURRENT_SOURCE_DIR}/public/tier1
)

set( SOURCE_SDK_WARNING_LEVEL "")

#-----------------------------------------------------------------
# Dynamic libraries from the engine
#-----------------------------------------------------------------
include( cmake/lib/tier0.cmake )
include( cmake/lib/vstdlib.cmake )

#-----------------------------------------------------------------
# Static libraries
#-----------------------------------------------------------------
add_subdirectory( tier1 )
add_subdirectory( tier2 )
add_subdirectory( vgui2/vgui_controls )

#-----------------------------------------------------------------
# Source SDK exported variables
#-----------------------------------------------------------------
set( SOURCE_SDK_DEFINES ${SOURCE_SDK_DEFINES} PARENT_SCOPE )
set( SOURCE_SDK_INCLUDE_PATHS ${SOURCE_SDK_INCLUDE_PATHS} PARENT_SCOPE )

set( SOURCE_SDK_LIBS
	vgui_controls
	${STEAM_API_LIBRARIES}
	tier2
	tier1
	tier0
	vstdlib
	PARENT_SCOPE
)
