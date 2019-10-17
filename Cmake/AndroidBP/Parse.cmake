
SET(ANDROID_BP_DEBUG_LOCAL OFF)

SET(ANDROID_BP_NONE    0)
SET(ANDROID_BP_DEFAULT 1)
SET(ANDROID_BP_HEADERS 2)
SET(ANDROID_BP_MODULES 3)
SET(ANDROID_BP_NORMAL  4)

include(${CMAKE_CURRENT_LIST_DIR}/ParseOther.cmake)

## Init env.
function(initBpEnv)
    SET(LOCAL_MODULE "" PARENT_SCOPE)
    SET(LOCAL_CFLAGS "" PARENT_SCOPE)
    SET(LOCAL_CPPFLAGS "" PARENT_SCOPE)
    SET(LOCAL_SRC_FILES "" PARENT_SCOPE)
    SET(LOCAL_C_INCLUDES "" PARENT_SCOPE)
    SET(LOCAL_SHARED_LIBRARIES "" PARENT_SCOPE)
    SET(LOCAL_STATIC_LIBRARIES "" PARENT_SCOPE)
    SET(LOCAL_EXPORT_C_INCLUDE_DIRS "" PARENT_SCOPE)
endfunction()

## unused.
function(doCatLine in out)
    string(LENGTH "${in}" texr_fun_length)
    message("texr_fun_length=${texr_fun_length}")
    string(FIND "${in}" "//" fun_num)
    if("${Brackets_num}" EQUAL "-1" )
        return()
    endif()

    string(FIND "${in}" "\n" fun_enter_num)
    string(SUBSTRING "${in}" "0" "${fun_num}" begin_text)
    message("begin_text=${begin_text}")
    string(SUBSTRING "${in}" "${fun_enter_num}" "${texr_fun_length}" end_text)
    message("end_text=${end_text}")

    set(${out} "${begin_text}${end_text}")
endfunction()

function(myListAppend org append out)
    if("${append}" STREQUAL "" )
        SET("${out}" "${org}" PARENT_SCOPE)
        return()
    endif()

    if("${org}" STREQUAL "" )
        SET("${out}" "${append}" PARENT_SCOPE)
    else()
        SET("${out}" "${org};${append}" PARENT_SCOPE)
    endif()
endfunction()

## Add local_path to export dir
function(exportExpand local_path)
    foreach(export ${LOCAL_EXPORT_C_INCLUDE_DIRS})
        if("${export}" STREQUAL ".")
            list(APPEND exportExpand_tmp "${local_path}")
        else()
            list(APPEND exportExpand_tmp "${local_path}/${export}")
        endif()
    endforeach()
    SET(LOCAL_EXPORT_C_INCLUDE_DIRS "${exportExpand_tmp}" PARENT_SCOPE)
endfunction()

## For export_static_lib_headers/export_shared_lib_headers in module
function(doOtherLibExport module module_type libName type)
    containsMoudle("${libName}_${type}" is_find)
    if(is_find)
        getMoudleExport("${libName}" "${type}" export_list)
        myListAppend("${LOCAL_EXPORT_C_INCLUDE_DIRS}" "${export_list}" doOtherLibExport_include_dirs)
        SET(LOCAL_EXPORT_C_INCLUDE_DIRS "${doOtherLibExport_include_dirs}" PARENT_SCOPE)
    else()
        addNeedExport("${module}" "${module_type}" "${libName}" "${type}")
    endif()
endfunction()

## For value in module item
function(BracketsToList line out)
    string(REPLACE "[" "" BracketsToList_line "${line}")
    string(REPLACE "]" "" BracketsToList_line "${BracketsToList_line}")
    string(REPLACE "\\\"" "'" BracketsToList_line "${BracketsToList_line}")
    string(REPLACE "\"" "" BracketsToList_line "${BracketsToList_line}")
    string(REPLACE "'" "\"" BracketsToList_line "${BracketsToList_line}")
    string(REPLACE "," " " BracketsToList_line "${BracketsToList_line}")
    string(REGEX REPLACE " +" " " BracketsToList_line "${BracketsToList_line}")
    string(STRIP ${BracketsToList_line} BracketsToList_line)
    string(REPLACE " " ";" BracketsToList_line "${BracketsToList_line}")
    set(${out} "${BracketsToList_line}" PARENT_SCOPE)
endfunction()

## For xxxx = [ xxxx, xxxx, xxx]
function(doVariable line)
    string(LENGTH "${line}" doVariable_length)
    string(FIND "${line}" "=" name_num)
    string(SUBSTRING ${line} "0" "${name_num}" doVariable_name)
    string(STRIP ${doVariable_name} doVariable_name)
    message("doVariable_name:${doVariable_name}")
    math(EXPR name_num "${name_num} + 1")
    string(SUBSTRING ${line} "${name_num}" "${doVariable_length}" doVariable_value)
    BracketsToList("${doVariable_value}" doVariable_value)
    SET("${doVariable_name}" "${doVariable_value}" PARENT_SCOPE)
endfunction()

## For xxxx_headers in Android.bp
function(doHeader line header_name)
    if("${line}" MATCHES "^export_include_dirs:.*")
        string(REPLACE "export_include_dirs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" export_include_dirs)
        SET(${header_name}_export_include_dirs "${export_include_dirs}" PARENT_SCOPE)
    endif()
endfunction()

## For xxxx_default in Android.bp
function(doDefault line default_name)

    if("${line}" MATCHES "^cflags: .*")
        string(REPLACE "cflags:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" c_flags)
        SET(${default_name}_c_flags "${c_flags}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^cppflags: .*")
        string(REPLACE "cppflags:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" cppflags)
        SET(${default_name}_cpp_flags "${cppflags}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^static_libs: .*")
        string(REPLACE "static_libs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" static_libs)
        SET(${default_name}_static_libs "${static_libs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^shared_libs: .*")
        string(REPLACE "shared_libs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" shared_libs)
        SET(${default_name}_shared_libs "${shared_libs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^srcs: .*")
        string(REPLACE "srcs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" srcs)
        SET(${default_name}_srcs "${srcs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^include_dirs: .*")
        string(REPLACE "include_dirs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" include_dirs)
        SET(${default_name}_include_dirs "${include_dirs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^export_include_dirs:.*")
        string(REPLACE "export_include_dirs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" export_include_dirs)
        SET(${default_name}_export_include_dirs "${export_include_dirs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^export_header_lib_headers:.*")
        string(REPLACE "export_header_lib_headers:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" export_header_lib_headers)
        SET(${default_name}_export_header_lib_headers "${export_header_lib_headers}" PARENT_SCOPE)
    endif()
endfunction()

## For cc_library_xx/cc_binary in Android.bp
function(doMoudle line)
    if("${line}" MATCHES "^srcs:.*")
        string(REPLACE "srcs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" srcs)
        myListAppend("${srcs}" "${LOCAL_SRC_FILES}" doMoudle_srcs)
        foreach(src ${doMoudle_srcs})
            if("${src}" MATCHES "^:.*$")
                string(REPLACE ":" "" src "${src}")
                string(STRIP ${src} src)
                list(REMOVE_ITEM doMoudle_srcs "${src}")
#                myListAppend("${LOCAL_SRC_FILES}" "${${doMoudle_default}_srcs}" LOCAL_SRC_FILES)
                list(APPEND doMoudle_srcs "${${src}_srcs}")
            elseif(NOT "${src}" MATCHES "^.*\\..*$")
                list(REMOVE_ITEM doMoudle_srcs "${src}")
                list(APPEND doMoudle_srcs ${${src}})
            endif()
        endforeach()
        SET(LOCAL_SRC_FILES "${doMoudle_srcs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^static_libs:.*")
        string(REPLACE "static_libs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" static_libs)
        myListAppend("${static_libs}" "${LOCAL_STATIC_LIBRARIES}" doMoudle_static_libs)
        SET(LOCAL_STATIC_LIBRARIES "${doMoudle_static_libs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^shared_libs:.*")
        string(REPLACE "shared_libs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" shared_libs)
        myListAppend("${shared_libs}" "${LOCAL_SHARED_LIBRARIES}" doMoudle_shared_libs)
        SET(LOCAL_STATIC_LIBRARIES "${doMoudle_shared_libs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^cppflags:.*")
        string(REPLACE "cppflags:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" cppflags)
        myListAppend("${cppflags}" "${LOCAL_CPPFLAGS}" doMoudle_cppflags)
        SET(LOCAL_CPPFLAGS "${doMoudle_cppflags}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^cflags:.*")
        string(REPLACE "cflags:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" cflags)
        myListAppend("${cflags}" "${LOCAL_CFLAGS}" doMoudle_cflags)
        SET(LOCAL_CFLAGS "${doMoudle_cflags}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^include_dirs:.*")
        string(REPLACE "include_dirs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" include_dirs)
        myListAppend("${include_dirs}" "${LOCAL_C_INCLUDES}" doMoudle_include_dirs)
        SET(LOCAL_C_INCLUDES "${doMoudle_include_dirs}" PARENT_SCOPE)
    elseif("${line}" MATCHES "^export_include_dirs:.*")
        string(REPLACE "export_include_dirs:" "" line "${line}")
        string(STRIP ${line} line)
        BracketsToList("${line}" export_include_dirs)
        myListAppend("${export_include_dirs}" "${LOCAL_EXPORT_C_INCLUDE_DIRS}" doMoudle_export_include_dirs)
        SET(LOCAL_EXPORT_C_INCLUDE_DIRS "${doMoudle_export_include_dirs}" PARENT_SCOPE)
    endif()
endfunction()

function(parseAndroidBP module_name type path)
    SET(bp_path ${path}/Android.bp)
    message("AndroidBP:${bp_path}")
    ## Rm android.bp comment.
    execute_process(COMMAND ${PROJECT_DIR}/Cmake/AndroidBP/rm_comment ${bp_path} OUTPUT_VARIABLE MyFile)
    STRING(REGEX REPLACE ";" "\\\\;" MyFile "${MyFile}")
    ## Read line android.bp.
    STRING(REGEX REPLACE "\n" ";" MyFile "${MyFile}")
    ## Read brackets num.
    SET(Brackets_num 0)
    ## Parsing  type.
    SET(bpType "${ANDROID_BP_NONE}")
    # SET(LOCAL_MODULE "")
    SET(default_name "")
    SET(normal_name "")
    SET(header_name "")
    SET(module_type "")

    SET(blockBrackets "0")
    SET(isBlock OFF)

    foreach(line ${MyFile})
        ## \n is converted to ";" when the file is read. It needs to be replaced.
        string(STRIP "${line}" line)
        if("${line}" MATCHES "^//+")
            continue()
        endif()
        string(REPLACE ";" "" line "${line}")
        ## Remove \t.
        string(REGEX REPLACE "(\t)+" " " line "${line}")
        string(REGEX REPLACE " +" " " line "${line}")
        #message("parseAndroidBP: ${line}")

        if("${line}" MATCHES ".*{$")
            math(EXPR Brackets_num "${Brackets_num} + 1")
            if("${Brackets_num}" EQUAL "1" )
                ## Set parsing type.
                if("${line}" MATCHES ".*defaults.*")
                    SET(bpType "${ANDROID_BP_DEFAULT}")
                elseif("${line}" MATCHES ".*headers.*")
                     SET(bpType "${ANDROID_BP_HEADERS}")
                elseif("${line}" MATCHES "^cc_.*")
                    SET(bpType "${ANDROID_BP_MODULES}")
                    if("${line}" MATCHES ".*cc_library.*")
                        SET(module_type "${type}")
                    elseif("${line}" MATCHES ".*cc_binary.*")
                        SET(module_type "${MK_EXECAB}")
                    elseif("${line}" MATCHES ".*cc_library_static.*")
                        SET(module_type "${MK_STATIC}")
                    elseif("${line}" MATCHES ".*cc_library_shared.*")
                        SET(module_type "${MK_SHARED}")
                    endif()
                else()
                    SET(bpType "${ANDROID_BP_NORMAL}")
                endif()
            elseif("${Brackets_num}" GREATER "1" )
                ## Block some line.
                if("${line}" MATCHES ".*host.*" OR "${line}" MATCHES ".*windows.*" OR "${line}" MATCHES ".*x86.*" OR "${line}" MATCHES ".*x86_64.*")
                    SET(blockBrackets "${Brackets_num}")
                    SET(isBlock ON)
                endif()
            endif()
        elseif("${line}" MATCHES "^}.*")
            math(EXPR Brackets_num "${Brackets_num} - 1")
            if("${Brackets_num}" EQUAL "0" )
                if("${bpType}" STREQUAL "${ANDROID_BP_MODULES}")
                    ## Add android target.
                    exportExpand("${LOCAL_PATH}")
                    if(ANDROID_BP_DEBUG_LOCAL)
                        message("LOCAL_MODULE=${LOCAL_MODULE}")
                        message("LOCAL_SRC_FILES=${LOCAL_SRC_FILES}")
                        message("LOCAL_CFLAGS=${LOCAL_CFLAGS}")
                        message("LOCAL_CPPFLAGS=${LOCAL_CPPFLAGS}")
                        message("LOCAL_SHARED_LIBRARIES=${LOCAL_SHARED_LIBRARIES}")
                        message("LOCAL_STATIC_LIBRARIES=${LOCAL_STATIC_LIBRARIES}")
                        message("LOCAL_C_INCLUDES=${LOCAL_C_INCLUDES}")
                        message("LOCAL_EXPORT_C_INCLUDE_DIRS=${LOCAL_EXPORT_C_INCLUDE_DIRS}")
                    endif()
                    if("${LOCAL_MODULE}" STREQUAL "${module_name}" )
                        if("${module_type}" STREQUAL "${type}" )
                            addTarget("${type}")
                            initBpEnv()
                            break()
                        endif()
                    endif()
                endif()
                initBpEnv()
                SET(bpType "${ANDROID_BP_NONE}")
            else()
                ## Remove block flag.
                if(isBlock)
                    if("${Brackets_num}" LESS "${blockBrackets}" )
                        SET(isBlock OFF)
                        SET(blockBrackets "0")
                    endif()
                endif()
            endif()
        elseif("${line}" MATCHES "^name: .*")
            string(REPLACE "name:" "" parseAndroidBP_name "${line}")
            string(STRIP ${parseAndroidBP_name} parseAndroidBP_name)
            string(REPLACE "\"" "" parseAndroidBP_name "${parseAndroidBP_name}")
            string(REPLACE "," "" parseAndroidBP_name "${parseAndroidBP_name}")
            ## Set type name.
            if("${bpType}" STREQUAL "${ANDROID_BP_DEFAULT}")
                SET(default_name "${parseAndroidBP_name}")
            elseif("${bpType}" STREQUAL "${ANDROID_BP_HEADERS}")
                SET(header_name "${parseAndroidBP_name}")
            elseif("${bpType}" STREQUAL "${ANDROID_BP_MODULES}")
                SET(LOCAL_MODULE "${parseAndroidBP_name}")
            elseif("${bpType}" STREQUAL "${ANDROID_BP_NORMAL}")
                SET(normal_name "${parseAndroidBP_name}")
            endif()
        elseif("${line}" MATCHES "^defaults: .*")
            if("${LOCAL_MODULE}" STREQUAL "${module_name}" )
                string(REPLACE "defaults:" "" line "${line}")
                string(STRIP ${line} line)
                BracketsToList("${line}" defaults)
                foreach(doMoudle_default ${defaults})
                    ## Parsing "default" in the module.
                    myListAppend("${LOCAL_CFLAGS}" "${${doMoudle_default}_c_flags}" LOCAL_CFLAGS)
                    myListAppend("${LOCAL_CPPFLAGS}" "${${doMoudle_default}_cpp_flags}" LOCAL_CPPFLAGS)
                    myListAppend("${LOCAL_SRC_FILES}" "${${doMoudle_default}_srcs}" LOCAL_SRC_FILES)
                    myListAppend("${LOCAL_C_INCLUDES}" "${${doMoudle_default}_include_dirs}" LOCAL_C_INCLUDES)
                    myListAppend("${LOCAL_STATIC_LIBRARIES}" "${${doMoudle_default}_static_libs}" LOCAL_STATIC_LIBRARIES)
                    myListAppend("${LOCAL_SHARED_LIBRARIES}" "${${doMoudle_default}_shared_libs}" LOCAL_SHARED_LIBRARIES)
                    myListAppend("${LOCAL_EXPORT_C_INCLUDE_DIRS}" "${${doMoudle_default}_export_include_dirs}" LOCAL_EXPORT_C_INCLUDE_DIRS)
                    ## Parsing "default->export_header_lib_headers->export_include_dirs" in the used module.
                    foreach(export_header_lib "${${doMoudle_default}_export_header_lib_headers}")
                        myListAppend("${LOCAL_EXPORT_C_INCLUDE_DIRS}" "${${export_header_lib}_export_include_dirs}" LOCAL_EXPORT_C_INCLUDE_DIRS)
                    endforeach()
                endforeach()
            endif()
        elseif("${line}" MATCHES "^export_header_lib_headers:.*")
            if("${LOCAL_MODULE}" STREQUAL "${module_name}" AND "${bpType}" STREQUAL "${ANDROID_BP_MODULES}")
                ## Parsing "cc_library_xx/cc_binary->export_header_lib_headers" in the module.
                string(REPLACE "export_header_lib_headers:" "" line "${line}")
                string(STRIP ${line} line)
                BracketsToList("${line}" export_header_lib_headers)
                foreach(export_header ${export_header_lib_headers})
                    myListAppend("${LOCAL_EXPORT_C_INCLUDE_DIRS}" "${${export_header}_export_include_dirs}" LOCAL_EXPORT_C_INCLUDE_DIRS)
                endforeach()
            elseif("${bpType}" STREQUAL "${ANDROID_BP_DEFAULT}")
                ## Parsing "xxx_default->export_header_lib_headers" in the default.
                doDefault("${line}" "${default_name}")
            endif()
        elseif("${line}" MATCHES "^export_static_lib_headers:.*")
            ## Parsing "export_static_lib_headers" in the module.
            if("${LOCAL_MODULE}" STREQUAL "${module_name}" AND "${bpType}" STREQUAL "${ANDROID_BP_MODULES}")
                string(REPLACE "export_static_lib_headers:" "" line "${line}")
                string(STRIP ${line} line)
                BracketsToList("${line}" export_static_lib_headers)
                foreach(export_static ${export_static_lib_headers})
                    doOtherLibExport("${LOCAL_MODULE}" "${module_type}" "${export_static}" ${MK_STATIC})
                endforeach()
            endif()
        elseif("${line}" MATCHES "^export_shared_lib_headers:.*")
            ## Parsing "export_shared_lib_headers" in the module.
            if("${LOCAL_MODULE}" STREQUAL "${module_name}" AND "${bpType}" STREQUAL "${ANDROID_BP_MODULES}")
                string(REPLACE "export_shared_lib_headers:" "" line "${line}")
                string(STRIP ${line} line)
                BracketsToList("${line}" export_shared_lib_headers)
                foreach(export_shared ${export_shared_lib_headers})
                    doOtherLibExport("${LOCAL_MODULE}" "${module_type}" "${export_shared}" ${MK_SHARED})
                endforeach()
            endif()
        elseif(NOT isBlock)
            ## If not block parsing line by type.
            if("${bpType}" STREQUAL "${ANDROID_BP_DEFAULT}")
                doDefault("${line}" "${default_name}")
            elseif("${bpType}" STREQUAL "${ANDROID_BP_NORMAL}")
                doDefault("${line}" "${normal_name}")
            elseif("${bpType}" STREQUAL "${ANDROID_BP_HEADERS}")
                doHeader("${line}" "${header_name}")
            elseif("${bpType}" STREQUAL "${ANDROID_BP_MODULES}")
                doMoudle("${line}")
            else()
                ## Parsing line "build = [xxxx.bp]".
                 if("${line}" MATCHES "build.*=.*")
                    string(REGEX REPLACE "build.*=" "" line "${line}")
                    string(STRIP ${line} line)
                    BracketsToList("${line}" doBuild_value)
                    parseOtherBP("${LOCAL_PATH}/${doBuild_value}")
                    #message("build:${module_name}")
                 elseif("${line}" MATCHES ".*=.*\\[")
                    doVariable("${line}")
                endif()
            endif()
        endif()
    endforeach()

    ## Find the dependencies of the module, and parsing.
    doMoudleDependencies("${module_name}_${type}")
    ## Find and set the export include of the module.
    doExportInclude("${module_name}_${type}")
endfunction()