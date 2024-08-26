#!/usr/bin/env tclsh8.6

###----------------------------------------------------------------###
#
#    Author : David Billsbrough <billsbrough@gmail.com>
#   Created : Sunday, August 25, 2024 at 12:39:23 PM (EDT)
#   License : GNU General Public License - version 2
#   Version : $Revision: 0.43 $
#  Warranty : None
#
#   Purpose : Convert an Elm address book for use with
#           :  NextCloud contact lists.
#
#  $Id: elm2nextcloud.tcl,v 0.43 2024/08/26 04:57:51 kc4zvw Exp kc4zvw $
#
###----------------------------------------------------------------###

# the Global variables

set filename1 "aliases.text"
set filename2 "addressbook_4.vcard"
set os_sep "/"
set elm_dir ".elm"

set Now 0

set report [file channels]

# ------------------------------

proc get_home_dir {} {
	set myHOME $::env(HOME)
	puts [format "My \$HOME directory is %s" $myHOME]
	return "$myHOME"
}

proc set_epoch_time {} {

	global Now

	set Now [clock seconds]
}

proc get_timestamp {} {

	global Now

	# return local date in format of "2022-01-28T03:19:32"
	set fmt2 "%Y-%m-%dT%H:%M:%S"
	set Target [clock format $Now -format $fmt2]

	return "$Target"
}

proc get_GMT_timestamp {} {

	global Now

	# return GMT date in format of "2022-01-28T03:19:32Z"
	set fmt1 "%Y%m%dT%H%M%SZ"
	set Target [clock format $Now -format $fmt1 -timezone :GMT]

	return "$Target"
}

proc delete_comment { name pos } {
	set result [string range $name 0 $pos]
	return "$result"
}

proc get_firstname { name pos } {
	set result [string range $name $pos+2 end-1]
	return "$result"
}

proc get_lastname { name pos } {
	set result [string range $name 0 $pos-1]
	return "$result"
}

proc get_fullname { first_name last_name } {
	set full_name [string cat "$first_name " "$last_name"]
	return "$full_name"
}

proc get_alias { alias } {
	set new_alias [string range $alias 0 end-1]
	return "$new_alias"
}

proc display_entry { alias name email } {

	puts [format "Converting %s (%s) <%s>" $name $alias $email]
}

proc write_address_header { report } {

	#global report

	#  Print title line 
	puts $report ""
	puts $report "### VCard file for import in to NextCloud contacts ###"
	puts $report ""
}

proc write_address_record { alias first last email report } {

	set fullname [get_fullname $first $last]
	set timestamp [get_GMT_timestamp]

	puts $report "BEGIN:VCARD"
	puts $report "VERSION:3.0"
	puts $report "PRODID:-//Sabre//Sabre VObject 4.4.2//EN"
	puts $report [format "N:%s;%s" $last $first]
	puts $report [format "FN:%s" $fullname]
	puts $report [format "EMAIL;TYPE=INTERNET;TYPE=HOME:%s" $email]
	puts $report "ADR;TYPE=WORK:;;;;;;USA"
	puts $report "TEL;TYPE=HOME,VOICE:nnn-nnn-nnnn"
	puts $report [format "TITLE:%s" $alias]
	puts $report "CATEGORIES:Demo Mode"
	puts $report [format "REV;VALUE=DATE-AND-OR-TIME:$timestamp"]
	puts $report "END:VCARD"
	puts $report ""
}

proc process_line { aline output } {
	#set pos1 0
	#set pos2 0

	set first ""
	set last ""

	#puts "$aline"

	set match1 [string first " = " $aline]
	set match2 [string last " = " $aline]

	set alias [string range $aline 0 $match1]
	set name  [string range $aline $match1+3 $match2]
	set email [string range $aline $match2+3 end]

	set match3 [string first "," $name]		;# search for a comma
	set match4 [string first ";" $name]		;# search for a semicolon

	set pos1 [expr {$match3}]
	set pos2 [expr {$match4}]
	#puts [format "Comma at '%d'; Semicolon at '%d'" $pos1 $pos2]

	if { [expr {$pos1}] > 0 } {
		set name [delete_comment $name, $pos1]
	}

	if { [expr {$pos2}] > 0 } {
		set first_name [get_firstname $name $pos2 ]
		set last_name [get_lastname $name $pos2 ]
		set fname [get_fullname $first_name $last_name ]
		set nalias [get_alias $alias ]
		#puts "First name is $first_name"
		#puts "Last name is $last_name"
		#puts "Fullname is $fname"
		#puts "Alias is $nalias"
	}

	display_entry $nalias $fname $email			;# display progress
	write_address_record $nalias \
		$first_name $last_name $email $output	;# write single entry
}


###------------------------------------------------------###
###--                   Main Routine                   --###
###------------------------------------------------------###

set_epoch_time

puts ""
puts "Converting 'elm' address book to import to contacts via vcards"
puts ""

set home [get_home_dir]

set elm [string cat $home$os_sep$elm_dir$os_sep$filename1]
set abook [string cat $home$os_sep$filename2]

puts ""
puts [format "The Elm mail Alias file is %s" $elm]
puts [format "The exported Address book file is %s" $abook]
puts ""

set input [open $elm "r"]
set output [open $abook "w"]

write_address_header $output

fconfigure $input -buffering line

gets $input data

while {$data != ""} {
	#puts $data
	process_line "$data" $output
	gets $input data
}

close $input
close $output

puts ""
puts "Conversion completed."

# End of Program
