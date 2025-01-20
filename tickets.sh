#!/bin/bash
#
# File:         tickets.sh
# Created:      270223
# Description:  tickets management script reworked 130524 to be more generic
#

## FUNCTIONS ##

generic_ticket()
{
 # parameters & env check
 [ ! -d "$TICKETS_ROOT" ] && return 1

 typeset ticket_id="$1"; shift # mandatory parameter
 [ -z "$ticket_id" ] && { return 1; }

 export TICKET_ID=$(echo $ticket_id | awk ' { print toupper($0); } ')
 export TICKET_HOME="$TICKETS_ROOT/$ticket_id"

 # Read "root" information: preferred work directory for the ticket
 #    if not set: use TICKET_HOME
 [ -s "$TICKET_HOME/root.txt" ] &&
   { cd $TICKET_HOME/$(< $TICKET_HOME/root.txt); } ||
   { cd $TICKET_HOME; }

 echo
 # Read and present "hello" message (hello.txt)
 [ -s "$TICKET_HOME/hello.txt" ] && { cat "$TICKET_HOME/hello.txt"; }
 export HELLO="$TICKET_HOME/hello.txt"
 echo

 export TICKET="$TICKET_ID"
 [ -s "$TICKET_HOME/.autoload" ] && { . "${TICKET_HOME}/.autoload"; }
}

gen-ticket-functions()
{
 [ -z "$1" ] && return 1

 typeset id="$(echo $1 | awk ' { print tolower($0); } '; )"
 typeset upid="$(echo $1 | awk ' { print toupper($0); } '; )"
 typeset id_nohyphen="$(echo $id | sed -e "s/-//g" )"

 eval "$id() { generic_ticket $id \$*; }"
 eval "$upid() { generic_ticket $id \$*; }"
 eval "$id_nohyphen() { generic_ticket $id \$*; }"
}

hello()
{
  [ -s "$TICKET_HOME/hello.txt" ] && { cat "$TICKET_HOME/hello.txt"; }
  [ -s "$TICKET_HOME/todo.txt" ] && { cat "$TICKET_HOME/todo.txt"; }
}

edhello() { vi "$TICKET_HOME/hello.txt"; }
edtodo() { vi "$TICKET_HOME/todo.txt"; }
home() { [ -d "$TICKET_HOME" ] && { cd "$TICKET_HOME"; return 0; } || { return $?; }; }
root() { [ -s "$TICKET_HOME/root.txt" ] && { cd $TICKET_HOME/$(< $TICKET_HOME/root.txt); }; }

alltickets()
{
 typeset id
 typeset desc=""
 typeset state=""

 [ ! -d "$TICKETS_ROOT" ] && return 1

 for ticket_d in $TICKETS_ROOT/*
 do
   state="O"
   [ -s "$ticket_d/state.txt" ] && { state=$(< "$ticket_d/state.txt" ); }

   [ -d "$ticket_d" -a -s "$ticket_d/README.md" ] &&
   {
     id=$(basename $ticket_d | awk ' { print toupper($0); } ' )

     [ -s "$ticket_d/linedesc.txt" ] &&
     {
       desc=$(< "$ticket_d/linedesc.txt" )
     } ||
     {
       desc="No description."
     }

     printf "%-12s %-6s %-35s\n" "$id" "$state" "$desc"
   }
 done
}

# List all tickets
tickets()
{
 typeset id
 typeset desc=""
 typeset state=""

 [ ! -d "$TICKETS_ROOT" ] && return 1

 for ticket_d in $TICKETS_ROOT/*
 do
   # if "state.txt" read it or set state to "open"
   state="O"
   [ -s "$ticket_d/state.txt" ] && { state=$(< "$ticket_d/state.txt" ); }

   [ -d "$ticket_d" -a -s "$ticket_d/README.md" -a "$state" == "O" ] &&
   {
     id=$(basename $ticket_d | awk ' { print toupper($0); } ' )

     [ -s "$ticket_d/linedesc.txt" ] &&
     {
       desc=$(< "$ticket_d/linedesc.txt" )
     } ||
     {
       desc="No description."
     }

     printf "%-16s %-35s\n" "$id" "$desc"
   }
 done
}

# generate functions for all tickets
setup_tickets()
{
 typeset ticket_d

 export TICKETS_ROOT="$PROJECT_HOME/tickets"
 export TICKETS_COUNT=0

 # allow to use a custom path instead of "tickets"
 [ -z "$TICKETS_LABEL" ] && export TICKETS_LABEL="tickets"
 [ -d "$PROJECT_HOME/$TICKETS_LABEL" ] && export TICKETS_ROOT="$PROJECT_HOME/$TICKETS_LABEL"

 # generate functions for all tickets
 [ -d "$TICKETS_ROOT" ] && for ticket_d in $TICKETS_ROOT/*
 do
   [ -d $ticket_d -a -s $ticket_d/README.md ] &&
   {
      gen-ticket-functions "$(basename $ticket_d)";
      let TICKETS_COUNT="(( $TICKETS_COUNT + 1 ))"
   }
 done
}

newticket()
{
  typeset rc

  [ -z "$TICKETS_ROOT" -o ! -d "$TICKETS_ROOT" ] && { echo "TICKETS_ROOT not set or invalid."; return 1; }
  [ -z "$2" ] && { echo "newticket id initial text for ticket"; return 1; }

  typeset id="$1"; shift
  typeset text="$*"

  typeset id_lower="$(echo $id | awk ' { print tolower($0); } ' )"
  typeset ticket_dir="${TICKETS_ROOT}/${id_lower}"

  # sanity: ensure does not ALREADY directory exists and create it
  [ -d "${ticket_dir}" ] && { echo "ticket directory for ${id} already exists."; return 1; }
  mkdir "${ticket_dir}" || { rc=$?; echo "failed creating directory for ${id}."; return $rc; }

  # create files: linedesc.txt README.md hello.txt
  echo "$text" > "${ticket_dir}/linedesc.txt"

  {
    cat << EOF
# Readme

${text}
EOF
} >> "${ticket_dir}/README.md"

 # hello: welcome message
 {
    cat << EOF
   welcome message for ticket: ${id}

   original description text: ${text}
EOF
 } >> "${ticket_dir}/hello.txt"

 echo "ticket files created. re-run: pload ${PROJECT}"
}

## MAIN ##

 setup_tickets

## EOF ##
