#!/bin/ksh
#
#            Tone Software Corporation BSD License ("License")
#
#                        Software Build Environment
#
# Please read this License carefully before downloading this software. By
# downloading or using this software, you are agreeing to be bound by the
# terms of this License. If you do not or cannot agree to the terms of
# this License, please do not download or use the software.
#
# A set of Jam configuration files and a Jam front-end for advanced
# software building with automatic dependency checking for the whole
# project. Provides a hierarchical project description while performing
# build procedures without changing directories. The resulting domain
# language changes emphasis from how to build to what to build. Provides
# separation of compilation artifacts (object files, binaries,
# intermediate files) from the original sources. Comes standard with
# ability to build programs, test suites, static and shared libraries,
# shared modules, code generation, and many others. Provides the bridge to
# ANT for building Java, with abilities to build JNI libraries.
#
# Copyright (c) 2003, 2005, Tone Software Corporation
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the Tone Software Corporation nor the names of
#     its contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#@(#)Title:     P4 frontend.
#@(#)Author:    Gennady F. Bystritsky (gfb@tonesoft.com)
#@(#)Version:   3.1
#@(#)Copyright: Tone Software Corporation, Inc. (1999-2000)

PRODSTAMP='
################################################################
# Script template. Copyright(c) 2000 Tone Software Corporation #
################################################################
'
DESCRIPTION="
  Show files not in p4 repository
"
ARGUMENTS="
  [-x<debug level>][-h]
"
    RedirectErrors=NO
ShowCleanupMessage=NO
     ShowProdStamp=NO
           SigList="1 2 3 8 15"

P4CMD=/usr/local/bin/p4

figure_p4cmd()
{
  eval `EntryPoint 1 figure_p4cmd`

  eval `SetInputFields PATH :`
  for item in "${@}"; do
    p4="${item}/p4"
    [ -x "${p4}" ] || continue
    [ "${P4CMD:+set}" = set ] || {
      P4CMD="${p4}"
      break
    }
    unset P4CMD
  done
}

main ()
{
  eval `EntryPoint 1 main`
  figure_p4cmd

  unset CLIENT DIR HOST PORT PASS USER FILE VERSION CMD_LINE
  ParseCommandParameters "c:d:H:p:P:u:f:sV" "${@}" || {
    PrintUsage
    return 2
  }
  eval `EntryPoint 1 main`
  set -o noglob
  set entry ${CMD_LINE}
  shift
  [ "${#}" -ne 0 ] && {
    case "${1}" in
      extra)
        shift
        showExtra "${@}"
        return ${?}
      ;;
      jobs)
        [ ${#} -eq 2 ] && {
          case "${2}" in
            -e)
              launch_p4 jobs -e "User=${LOGNAME}&Status=open"
              return ${?}
            ;;
          esac
        }
      ;;
      format|reformat)
        shift
        formatSource "${@}"
        return ${?}
      ;;
    esac
  }
  launch_p4 "${@}"
  return ${?}
}

OnOption ()
{
  eval `EntryPoint 3 OnOption`

  case "${1}" in
    c)
      CLIENT="${2}"
    ;;
    d)
      DIR="${2}"
    ;;
    H)
      HOST="${2}"
    ;;
    p)
      PORT="${2}"
    ;;
    P)
      PASS="${2}"
    ;;
    s)
      STATUS=YES
    ;;
    V)
      VERSION=YES
    ;;
    u)
      USER="${2}"
    ;;
    f)
      FILE="${2}"
    ;;
    *)
      return 1
    ;;
  esac
  return 0
}

OnArguments ()
{
  eval `EntryPoint 2 OnArguments`
  CMD_LINE="${@}"
  return 0
}

formatSource()
{
  eval `EntryPoint 3 formatSource`

  NOREVERSE=YES
  unset JUST_SHOW
  [ ${#} -eq 0 ] || {
    while getopts "rn" opt 2>/dev/null; do
      case "${opt}" in
        r)
          unset NOREVERSE
        ;;
        n)
          JUST_SHOW=YES
        ;;
        *)
          ShowMsg "USAGE: p4 reformat [-r] [<filespec>]"
          return 2
        ;;
      esac
    done
    shift `expr "${OPTIND}" - 1`
  }
  params="${@}"
  set entry `getClientRoot`
  shift
  CLIENT_ROOT=`GenDirPath "${1}"`
  [ ${#} -ne 1 -o "${CLIENT_ROOT:+set}" != set ] && {
    ErrMsg "Client view root is not accessible."
    return 2
  }
  launch_p4 -s opened ${params} | "${awk}" '
    NF>3 && $1~/^info/ && $3=="-" && $4!="delete" {
      path=$2
      sub("[#].*$","",path)
      print path
    }
  ' | {
    while read line; do
      launch_p4 -s fstat "${line}"
    done
  } | {
    if [ "${NOREVERSE}" = YES ]; then
      format=repository
    else
      format=user
    fi
    while read line; do
      set entry ${line}
      [ ${#} -eq 4 -a "${3}" = "clientFile" ] && {
        source_path=${4}
        case "${source_path}" in
          *.java)
            JAVA_PROP="${CLIENT_ROOT}/config/p4-java-style.jin"
            cmd='jindent -nobak ${NOREVERSE:+-p ${JAVA_PROP}} "${source_path}"'
            if [ "${JUST_SHOW}" = YES ]; then
              eval echo "${cmd}"
            else
              eval "${cmd}" || {
                break
              }
              echo "${source_path} formatted (${format} style)"
            fi
          ;;
        esac
      }
    done|makePathShorter
  }
  return 0
}

launch_p4 ()
{
  eval `EntryPoint 5 launch_p4`
  "${P4CMD}" \
    ${CLIENT:+-c "${CLIENT}"} \
    ${DIR:+-d "${DIR}"} \
    ${HOST:+-H "${HOST}"} \
    ${PORT:+-p "${PORT}"} \
    ${PASS:+-P "${PASS}"} \
    ${USER:+-u "${USER}"} \
    ${FILE:+-x "${FILE}"} \
    ${STATUS:+-s} \
    ${VERSION:+-V} \
  "${@}"
}

showExtra ()
{
  eval `EntryPoint 3 showExtra`
  [ ${#} -gt 1 ] && {
    PrintUsage
    return 2
  }
  target=${1}
  set entry `getClientRoot`
  shift
  client_root=`GenDirPath "${1}"`
  [ ${#} -ne 1 -o "${client_root:+set}" != set ] && {
    ErrMsg "Client view root is not accessible."
    return 2
  }
  [ "${target:+set}" = set ] || {
    target="${client_root}"
  }
  [ "`basename ${target}`" = "..." ] && {
    target=`dirname ${target}`
  }
  [ "${DIR:+set}" = set ] && {
    case "${target}" in
      /*)
      ;;
      *)
        target="${DIR}/${target}"
      ;;
    esac
  }
  target=`GenDirPath "${target}"`
  [ "${target:+set}" = set ] || {
    ErrMsg "Specified directory is not accessible."
    return 2
  }
  case "${target}" in
    ${client_root}*)
    ;;
    *)
      ErrMsg "Specified directory is not in client view."
      return 2
    ;;
  esac
  {
    launch_p4 have "${target}/..." | {
      sed -n 's%^.*\('"${target}"'.*\)$%\1%p'
    }
    find "${target}" -type f -print
  } | {
    sort | uniq -u
  } | {
    while read line; do
      [ "${line:+set}" = set ] && {
        launch_p4 -s opened "${line}"
      }
    done
  } | {
    sed -n 's/^error: \([^ ][^ ]*\) .*$/\1/p'
  } | makePathShorter
}

makePathShorter()
{
  eval `EntryPoint 5 makePathShorter`
  sed "s%^`pwd`/%./%;s%^${HOME}/%~/%"
}

getClientRoot ()
{
  eval `EntryPoint 4 getClientRoot`

  STATUS= launch_p4 client -o | {
    sed -n 's/^[        ]*Root[         ]*:[    ]*//p'
  }
  return 0
}

##################################################
## Here 'library.sh' must be copied or included ##
##################################################
. library.sh
