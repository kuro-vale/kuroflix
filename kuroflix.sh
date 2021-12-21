#!/bin/bash


get_url_titles()
{
read -p "What do you want to watch?: " search
search=$(echo $search | tr ' ' '+')
regex='s_^[[:space:]]*<a href="'$url'([^"]*)" class=.*_\1_p'
media_links=$(curl -s "$url" -G -d "s=$search" | sed -n -E "$regex")
if [ -z "$media_links" ]; then
echo -e "No search results for $search\nVerify that you didn't have erros like: 'Abatar' instead of 'Avatar', 'Ironman' instead of 'Iron Man'"
exit
fi
}


movies_english()
{
url="https://gototub.com/"
get_url_titles
i=1
# deprecated
for link in ${media_links[*]}
do
	echo "$i. $link" # | sed "s/-full-movie.*/ /"
	i=$((i+1))
done
choice=3
i=1
for link in ${media_links[*]}
do
	if [ $choice -eq $i ]; then
	movie=$link
	fi
	i=$((i+1))
done
echo $movie
#firefox "$url/$movie" >/dev/null 2>&1
echo "Goodbye"
}


movies_english
