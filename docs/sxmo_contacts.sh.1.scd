sxmo_contacts.sh(1)

# NAME

sxmo_contact.sh - a simple contacts manager

# SYNOPSIS

sxmo_contacts.sh allows you to store and lookup contacts in a variety of ways.

# DESCRIPTION

TODO

# OPTIONS

_string_ (default)
	If _string_ is given, search the contact book for _string_. The output
	will be CONTACTNAME: PHONENUMBER for each hit. Note it uses grep so
	multiple hits are possible.
	If no argument is given, then return *all* contacts from the contact
	book and also every number that has ever texted or called you.
	The output will be CONTACTNAME: PHONENUMBER (if in the contact book) or
	???: PHONENUMBER if not.

*--all* [--no-groups]
	Return all the contacts in *only* in your contact book. With --no-group avoids
	groups. The output will be CONTACTNAME: PHONENUMBER.

*--no-groups*
	Return all the contacts in your contact book *and* all the phone numbers
	that have texted or called you, except groups. The form

*--unknown*
	Return all the phone numbers that have ever texted or called you. The
	output will be one phone number per line.

*--texted*
	Return all the phone numbers that have ever texted you. The output will
	be CONTACTNAME: PHONENUMBER (if in contact book) or ???: PHONENUMBER (if
	not).

*--called*
	Same, but for those who have ever called you.

*--me*
	Return the phonenumber associated with the *Me* entry in contact book.

*--name-or-nuber* _phonenumber_
	Return the contact name (if present) or _phone number_ (if not).

*--name* _phonenumber_
	Return the contact name (if present) or *???* (if not)

# EXIT STATUS

# RETURN VALUE

# ERRORS

# ENVIRONMENT

# FILES

~/.local/share/sxmo/modem/modemlog.tsv - a TSV file containing every phone
number that has ever texted or called you.

~/.config/sxmo/contacts.tsv - a TSV file containing contacts in the format
PHONENUMBER tab CONTACTNAME

# NOTES

# BUGS

# EXAMPLES

# AUTHORS

# REPORTING BUGS

# COPYRIGHT

# SEE ALSO
