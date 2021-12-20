#!/bin/bash
url="https://gototub.com"


movie()
{
# Get movies list after search
read -p "What do you want to watch?: " search
search=$(echo $search | tr ' ' '-')
movies=$(curl -s "$url" -G -d "s=$search" | sed -n -E 's_^[[:space:]]*<a href=".*/watch-([^"]*)" data-url=.*_\1_p')
for link in ${movies[*]}
do
	echo $link | sed "s/-full-movie.*/ /"
done
}

movie
