#!/bin/bash


get_url_titles()
{
# Get a url list of the media searchead
read -p "What do you want to watch?: " search
search=$(echo $search | tr ' ' '+')
media_links=$(curl -s "$url" -G -d "s=$search" | sed -n -E "$regex")
if [ -z "$media_links" ]; then
echo -e "No search results for $search\nVerify that you didn't have erros like: 'Abatar' instead of 'Avatar', 'Ironman' instead of 'Iron Man'"
exit
fi
}


get_user_choice()
{
# Get the user choice
read -p "Enter the prefix number of what do you want to watch: " choice
i=1
for link in ${media_links[*]}
do
	if [ $choice -eq $i ]; then
	media=$link
	fi
	i=$((i+1))
done
}


reproduce_embedded_link()
{
	echo "Reproducing $media"
	embedded_links=$(curl -s "$url$media" | sed -n -E "$regex_embed")
	for link in ${embedded_links[*]}
	do
		firefox $link >/dev/null 2>&1
		read -p "Doesn't work? Press 5 to try with another link or enter to exit: " retry
		if [ $retry -eq 5 ]; then
			continue
		fi >/dev/null 2>&1
		echo "Goodbye"
		exit
	done
}


select_episodes()
{
	# Get list of episodes, then user will choice which episode reproduce
	i=1
	media_links=$(curl -s "$url$media" | sed -n -E "$regex_episodes")
	for episode in ${media_links[*]}
	do
		echo "$i. $episode"
		i=$((i+1))
	done
	get_user_choice
}


media_english()
{
url="https://gototub.com/"
regex='s_^[[:space:]]*<a href="'$url'([^"]*)" data-url=.*_\1_p'
get_url_titles
# Print media titles
i=1
for link in ${media_links[*]}
do
	if [[ $link =~ watch-.* ]]; then
		echo "$i. $link" | sed -n -E 's_watch-(.*)(-full-movie).*_\1_p'
	else
		echo "$i. $link" | sed "s/-full-movie.*//"
	fi
	i=$((i+1))
done
get_user_choice
regex_embed='s_[[:space:]]*<iframe src="([^"]*)" frameborder=.*_\1_p'
# Distinguish between movie or series
if [[ $media =~ ^series\/ ]]; then
	# When series selected, search episodes an change $media to te selected episode
	url_episodes="https://gototub.com/episode/"
	regex_episodes='s_[[:space:]]*<a href="'$url_episodes'([^"]*)">.*_\1_p'
	select_episodes
	url=$url_episodes
	media+="/"  # Fix bug that don't allow to curl if episodes don't end with: /
fi
reproduce_embedded_link
}


media_english
