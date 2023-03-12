# CMakeBBLM. See https://github.com/sakra/CMakeBBLM
#
# This script generates a BBEdit codeless language module for CMake from cmake.plist.in
# See https://www.barebones.com/support/develop/clm.html
#
# Copyright (c) 2016-2021 Sascha Kratky
#
# Distributed under the MIT License. See accompanying license file.

function(resolve_templates _propNames)
	set (${_propNames} "")
	set (_languages "C" "CXX" "Fortran" "ASM")
	if (NOT CMAKE_VERSION VERSION_LESS "3.8.0")
		list (APPEND _languages "CSharp" "CUDA")
	endif()
	if (NOT CMAKE_VERSION VERSION_LESS "3.16.0")
		list (APPEND _languages "OBJC" "OBJCXX")
	endif()
	if (NOT CMAKE_VERSION VERSION_LESS "3.19.0")
		list (APPEND _languages "ISPC")
	endif()
	if (NOT CMAKE_VERSION VERSION_LESS "3.21.0")
		list (APPEND _languages "HIP")
	endif()
	# resolve known templates, e.g., <CONFIG>, <LANG>, ...
	set (_configurations "None" "Debug" "MinSizeRel" "Release" "RelWithDebInfo")
	set (_resolvedPropNames "")
	foreach (_unresolvedPropName IN LISTS ARGN)
		if (_unresolvedPropName MATCHES "<CONFIG>" AND _unresolvedPropName MATCHES "<LANG>")
			foreach (_config ${_configurations})
				foreach (_lang ${_languages})
					if (NOT _config STREQUAL "None")
						string (TOUPPER "${_config}" _config)
						string (REPLACE "<CONFIG>" "${_config}" _propName "${_unresolvedPropName}")
						string (REPLACE "<LANG>" "${_lang}" _propName "${_propName}")
						list (APPEND _resolvedPropNames ${_propName})
					endif()
				endforeach()
			endforeach()
		elseif (_unresolvedPropName MATCHES "<CONFIG>")
			foreach (_config ${_configurations})
				if (_config STREQUAL "None")
					# handle special build type "None" which requires unqualified property name
					string (REGEX REPLACE "_?<CONFIG>_?" "" _propName "${_unresolvedPropName}")
				else()
					string (TOUPPER "${_config}" _config)
					string (REPLACE "<CONFIG>" "${_config}" _propName "${_unresolvedPropName}")
				endif()
				list (APPEND _resolvedPropNames ${_propName})
			endforeach()
		elseif (_unresolvedPropName MATCHES "GNU<LANG>")
			foreach (_lang "CC" "CXX" "G77")
				string (REPLACE "<LANG>" "${_lang}" _propName "${_unresolvedPropName}")
				list (APPEND _resolvedPropNames ${_propName})
			endforeach()
		elseif (_unresolvedPropName MATCHES "ASM<DIALECT>")
			foreach (_lang "ASM" "ASM_NASM" "ASM_MASM" "ASM-ATT" "ASM_MARMASM")
				string (REPLACE "ASM<DIALECT>" "${_lang}" _propName "${_unresolvedPropName}")
				list (APPEND _resolvedPropNames ${_propName})
			endforeach()
		elseif (_unresolvedPropName MATCHES "<LANG>")
			foreach (_lang ${_languages})
				string (REPLACE "<LANG>" "${_lang}" _propName "${_unresolvedPropName}")
				list (APPEND _resolvedPropNames ${_propName})
			endforeach()
		elseif (_unresolvedPropName MATCHES "CMP<NNNN>")
			execute_process(
				COMMAND ${CMAKE_COMMAND} --help-policies
				OUTPUT_VARIABLE _output
				OUTPUT_STRIP_TRAILING_WHITESPACE)
			string (REPLACE "\n" ";" _output "${_output}")
			foreach (_line IN LISTS _output)
				if (_line MATCHES "^ *CMP([0-9]+) *$")
					list (APPEND _policies "${CMAKE_MATCH_1}")
				endif()
			endforeach()
			foreach (_policy IN LISTS _policies)
				string (REPLACE "<NNNN>" "${_policy}" _propName "${_unresolvedPropName}")
				list (APPEND _resolvedPropNames ${_propName})
			endforeach()
		elseif (_unresolvedPropName MATCHES "\\(([0-9]+)..([0-9]+)\\)")
			# handle properties with trailing number, e.g., CMAKE_MATCH_(0..9)
			foreach (_index RANGE ${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
				string (REPLACE "${CMAKE_MATCH_0}" "${_index}" _propName "${_unresolvedPropName}")
				list (APPEND _resolvedPropNames ${_propName})
			endforeach()
		elseif (_unresolvedPropName MATCHES "<[a-zA-Z0-9_-]+>")
			message(STATUS "Skipping ${_unresolvedPropName}")
		else()
			list (APPEND _resolvedPropNames ${_unresolvedPropName})
		endif()
	endforeach()
	# skip properties containing unknown unresolved templates
	list (REMOVE_DUPLICATES _resolvedPropNames)
	set (${_propNames} "")
	foreach (_resolvedPropName IN LISTS _resolvedPropNames)
		if (_resolvedPropName MATCHES "<[a-zA-Z0-9_-]+>")
			message(STATUS "Skipping ${_resolvedPropName}")
		else()
			list (APPEND ${_propNames} ${_resolvedPropName})
		endif()
	endforeach()
	set (${_propNames} ${${_propNames}} PARENT_SCOPE)
endfunction()

execute_process(
	COMMAND ${CMAKE_COMMAND} --help-command-list
	OUTPUT_VARIABLE _output
	OUTPUT_STRIP_TRAILING_WHITESPACE)
string (REPLACE "\n" ";" _output "${_output}")
foreach (_line IN LISTS _output)
	if (_line MATCHES "^([a-z_]+) *$")
		list (APPEND _commandList "${CMAKE_MATCH_1}")
	else()
		message(STATUS "Skipping line \"${_line}\"")
	endif()
endforeach()
#message (STATUS "${_commandList}")

if (CMAKE_VERSION VERSION_LESS "3.0.0")
	execute_process(
		COMMAND ${CMAKE_COMMAND} --help-compatcommands
		OUTPUT_VARIABLE _output
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	string (REPLACE "\n" ";" _output "${_output}")
	foreach (_line IN LISTS _output)
		if (_line MATCHES "^  ([a-z_]+) *$")
			list (APPEND _deprecatedCommandList "${CMAKE_MATCH_1}")
		endif()
	endforeach()
	#message (STATUS "${_deprecatedCommandList}")
endif()

# generate keyword list without deprecated commands
set (BBLMKeywordList ${_commandList})
if (_deprecatedCommandList)
	list (REMOVE_ITEM BBLMKeywordList ${_deprecatedCommandList})
endif()
list (SORT BBLMKeywordList)
list (REMOVE_DUPLICATES BBLMKeywordList)
string (
	REGEX REPLACE "[A-Za-z0-9_-]+" "\t\t<string>\\0</string>"
	BBLMKeywordList "${BBLMKeywordList}")
string (REPLACE ";" "\n" BBLMKeywordList "${BBLMKeywordList}")
#message (STATUS "${BBLMKeywordList}")

execute_process(
	COMMAND ${CMAKE_COMMAND} --help-property-list
	OUTPUT_VARIABLE _output
	OUTPUT_STRIP_TRAILING_WHITESPACE)
string (REPLACE "\n" ";" _output "${_output}")
foreach (_line IN LISTS _output)
	if (_line MATCHES "^([A-Za-z0-9_<>-]+) *$")
		list (APPEND _propertyList "${CMAKE_MATCH_1}")
	else()
		message(STATUS "Skipping line \"${_line}\"")
	endif()
endforeach()
resolve_templates(_propertyList ${_propertyList})
#message (STATUS "${_propertyList}")

# cmake variables
execute_process(
	COMMAND ${CMAKE_COMMAND} --help-variable-list
	OUTPUT_VARIABLE _output
	OUTPUT_STRIP_TRAILING_WHITESPACE)
string (REPLACE "\n" ";" _output "${_output}")
foreach (_line IN LISTS _output)
	if (_line MATCHES "^([A-Za-z0-9_<>-]+) *$")
		list (APPEND _variableList "${CMAKE_MATCH_1}")
	else()
		message(STATUS "Skipping line \"${_line}\"")
	endif()
endforeach()

# cmake environment variables
if (NOT CMAKE_VERSION VERSION_LESS "3.0.0")
	execute_process(
		COMMAND ${CMAKE_COMMAND} --help-manual cmake-env-variables
		OUTPUT_VARIABLE _output
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	string (REPLACE "\n" ";" _output "${_output}")
	set (_variable "")
	foreach (_line IN LISTS _output)
		if(_line MATCHES "^-+ *$")
			if (_variable)
				list (APPEND _variableList "${_variable}")
				set (_variable "")
			endif()
		elseif (_line MATCHES "^([A-Za-z0-9_<>-]+) *$")
			set (_variable "${_line}")
		endif()
	endforeach()
endif()

# explicitly add variables missed by command parser
list(APPEND _variableList "CMAKE_ARGV(0..9)" "CMAKE_MATCH_(0..9)")
# add undocumented, but useful CMake variables
list(APPEND _variableList "CMAKE_SKIP_ASSEMBLY_SOURCE_RULES" "CMAKE_SKIP_PREPROCESSED_SOURCE_RULES" "CMAKE_SKIP_RULE_DEPENDENCY")
list(APPEND _variableList "CMAKE_DISABLE_SOURCE_CHANGES" "CMAKE_DISABLE_IN_SOURCE_BUILD")
list(APPEND _variableList "CMAKE_LINK_DEPENDS_DEBUG_MODE")
list(APPEND _variableList "CMAKE_NINJA_FORCE_RESPONSE_FILE")
resolve_templates(_variableList ${_variableList})
#message (STATUS "${_variableList}")

# parse keywords from command help
foreach (_command IN LISTS _commandList)
	execute_process(
		COMMAND ${CMAKE_COMMAND} --help-command ${_command}
		OUTPUT_VARIABLE _output
		OUTPUT_STRIP_TRAILING_WHITESPACE)
	string (REGEX MATCHALL "${_command}\\([^)]*\\)" _signatures "${_output}")
	#message (STATUS "${_signatures}")
	foreach (_singnature IN LISTS _signatures)
		string (REGEX MATCHALL "[A-Z@][A-Z0-9_]+(<[A-Z0-9_]+>)?" _keywords "${_singnature}")
		list (APPEND _keywordList ${_keywords})
	endforeach()
endforeach()
# remove false positives, e.g.:
#   mark_as_advanced([CLEAR|FORCE] VAR VAR2 VAR...)
#   add_definitions(-DFOO -DBAR ...)
list (REMOVE_ITEM _keywordList "FOO" "BAR" "DFOO" "DBAR" "VAR" "VAR2")
# explicitly add keywords missed by command parser
list (APPEND _keywordList "ARGV(0..9)" "ARGC" "ARGV" "ARGN")
list (APPEND _keywordList "STATUS" "WARNING" "AUTHOR_WARNING" "SEND_ERROR" "FATAL_ERROR" "DEPRECATION")
list (APPEND _keywordList "DIRECTORY" "NAME" "EXT" "NAME_WE" "PATH" "ABSOLUTE" "REALPATH")
resolve_templates(_keywordList ${_keywordList})
#message (STATUS "${_keywordList}")

set (BBLMPredefinedNameList ${_propertyList} ${_variableList} ${_keywordList})
list (SORT BBLMPredefinedNameList)
list (REMOVE_DUPLICATES BBLMPredefinedNameList)
string (
	REGEX REPLACE "[@A-Za-z0-9_<>-]+" "\t\t<string>\\0</string>"
	BBLMPredefinedNameList "${BBLMPredefinedNameList}")
string (REPLACE ";" "\n" BBLMPredefinedNameList "${BBLMPredefinedNameList}")
#message (STATUS "${BBLMPredefinedNameList}")

if (CMAKE_VERSION VERSION_LESS "3.0.0")
	set (BBLMReferenceSearchURLTemplate "http://www.cmake.org/cmake/help/v${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}/cmake.html#__SYMBOLNAME__")
else()
	set (BBLMReferenceSearchURLTemplate "http://www.cmake.org/cmake/help/v${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}/search.html?q=__SYMBOLNAME__&amp;check_keywords=yes&amp;area=default")
endif()

configure_file("${CMAKE_CURRENT_LIST_DIR}/cmake.plist.in" "${CMAKE_CURRENT_LIST_DIR}/cmake.plist")
