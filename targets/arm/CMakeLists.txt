set(NAME arm)

# Get files from Drivers directory
file(GLOB_RECURSE allDriversFiles  "Drivers/*.c")

# and disable warnings
foreach(file ${allDriversFiles})
	set_source_files_properties(${file} PROPERTIES COMPILE_FLAGS "-w")
endforeach(file)

# Disable warnings for LD file
set_source_files_properties(${SYSCALLS_FILE} PROPERTIES COMPILE_FLAGS "-w")

# Get all source files
file(GLOB_RECURSE SOURCES_AUTO
		Drivers/*.c
		Src/*.c
		Src/*.cpp
		Core/Src/*.c
		Core/Src/*.cpp
		*.s
)

# Get all include directories
ReadVariables(${CMAKE_CURRENT_SOURCE_DIR}/Makefile "C_INCLUDES")

set(HAL_INCLUDES "")
foreach(incc ${C_INCLUDES})
	string(REPLACE "-I" "" incc ${incc})
	set(HAL_INCLUDES "${HAL_INCLUDES}; ${incc} ")
endforeach(incc)

include_directories(${HAL_INCLUDES})

# generate executable
add_executable(${NAME} ${SOURCES_AUTO} ${C_SOURCES} ${SYSCALLS_FILE})

set_target_properties(${NAME} PROPERTIES LINK_FLAGS "-T ${PLATFORM_LINKER_SCRIPT} -Xlinker -print-memory-usage -Wl,--gc-sections -specs=nano.specs -flto -lc -u _printf_float ${ARMFLOAT}")

target_link_libraries(${NAME}
		core
)

target_include_directories(${NAME} PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}/../../core
		)

add_custom_command(TARGET ${NAME}
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -v -O ihex "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME}.hex"
		COMMAND ${CMAKE_OBJCOPY} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${NAME}.elf)

target_jlink_flash(${NAME} 0x8000000)

target_stlink_flash(${NAME} stm32f4x.cfg)