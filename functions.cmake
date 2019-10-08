function(target_format_sources TARGET SOURCES)
    if(CLANG_FORMAT)
        add_custom_target(${NAME}.format
            COMMAND ${CLANG_FORMAT} -style=file -i ${SOURCES}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            COMMENT "Formatting files: '${SOURCES}'"
            )
    else(CLANG_FORMAT)
        add_custom_target(${NAME}.format
            COMMAND ""
            COMMENT "Clang format has not been found. Code formatting is not available. "
            )
    endif()
endfunction(target_format_sources)

function(target_generate_hex TARGET)
  set (EXEC_OBJ ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${TARGET})
  set (HEX_OBJ ${EXEC_OBJ}.hex)

  set_target_properties(${TARGET} PROPERTIES HEX_FILE ${HEX_OBJ})

  add_custom_command(OUTPUT ${HEX_OBJ}
      COMMAND ${CMAKE_OBJCOPY} -O ihex ${EXEC_OBJ} ${HEX_OBJ}
      DEPENDS ${TARGET}.size
  )

  add_custom_target (${TARGET}.hex ALL DEPENDS ${HEX_OBJ})
endfunction(target_generate_hex)

function(target_memory_report TARGET)
    get_property(binary TARGET ${TARGET} PROPERTY RUNTIME_OUTPUT_NAME)

    add_custom_command(OUTPUT ${TARGET}.size
		COMMAND ${CMAKE_GCC_SIZE} -A -d $<TARGET_FILE:${TARGET}>
		COMMAND ${CMAKE_GCC_SIZE} -A -d $<TARGET_FILE:${TARGET}> > ${TARGET}.size
		COMMAND ${CMAKE_GCC_SIZE} -B -d $<TARGET_FILE:${TARGET}>
		DEPENDS ${TARGET}
        )
    set_property(TARGET ${NAME} APPEND_STRING PROPERTY LINK_FLAGS " -Wl,-Map=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME}.map")
endfunction(target_memory_report)

function(target_asm_listing TARGET)
    get_property(binary TARGET ${TARGET} PROPERTY RUNTIME_OUTPUT_NAME)

    add_custom_target(${TARGET}.asm
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORTS_PATH}
        COMMAND ${CMAKE_OBJDUMP} -dSC $<TARGET_FILE:${TARGET}> > ${REPORTS_PATH}/${TARGET}.lss
        DEPENDS ${TARGET}
    )
endfunction(target_asm_listing)

function(ReadVariables MKFile VARIABLE_NAME)
    file(READ "${MKFile}" FileContents)
    string(REPLACE "\\\n" "" FileContents ${FileContents})
    string(REPLACE "\n" ";" FileLines ${FileContents})
    list(REMOVE_ITEM FileLines "")
    foreach(line ${FileLines})
        string(REPLACE "=" ";" line_split ${line})
        list(LENGTH line_split count)
        if (count LESS 2)
            continue()
        endif()
        list(GET line_split -1 value)
        string(STRIP ${value} value)
        separate_arguments(value)
        list(REMOVE_AT line_split -1)
        foreach(var_name ${line_split})
            string(STRIP ${var_name} var_name)
            if (var_name STREQUAL VARIABLE_NAME)
                set(${var_name} ${value} PARENT_SCOPE)
            endif()

        endforeach()
    endforeach()
endfunction()
