function calc_offset(string) {
	split(string,v, "=")
	gsub(/"/, "", v[2])
	n = v[2] + 0
	return n * 512
}

function calc_count(string) {
	split(string,v, "=")
	split(v[2],x, "\"")
	n= x[2] + 0
	return n * 512
}

/\<request\>/ {
	offset=calc_offset($3)
	count=calc_count($4)
	printf("\t\t\t\t\t%s %s offset=\"%d\" count=\"%d\"/>\n",
	       $1, $2, offset, count);
	next
}

{ print $0 }
