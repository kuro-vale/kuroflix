#!/bin/bash
# Dependencies: curl, sed, firefox(Change browser below if you want to use another one)
BROWSER=firefox

get_url_titles()
{
# Get a url list of the media searchead
	clear
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
# Get the media url based on the user choice
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


select_episodes()
{
# Print a list of episodes, then user will choose which episode reproduce
	clear
	i=1
	media_links=$(curl -s "$url$media" | sed -n -E "$regex_episodes")
	for episode in ${media_links[*]}
	do
		echo "$i. $episode"
		i=$((i+1))
	done
	get_user_choice
}


reproduce_embedded_link()
{
# Search the embedded link in the media url, then reproduce it in firefox
	clear
	echo "Reproducing $media"
	embedded_links=$(curl -s "$url$media" | sed -n -E "$regex_embed")
	for link in ${embedded_links[*]}
	do
		$BROWSER $link >/dev/null 2>&1
		read -p "Want to try with another link? Y/N: " retry
		if [ ${retry^^} = "Y" ]; then
			continue
		else
			clear
			echo "Goodbye"
			exit
		fi >/dev/null 2>&1
	done
	clear
	echo "Sorry, can't find another link :(, Goodbye!"
	exit
}


save_cache()
{
# Save the variables needed to reproduce media in cache.tmp, cache_media save the url of the next episode
	choice=$((choice+1))
	i=1
	for link in ${media_links[*]}
	do
		if [ $choice -eq $i ]; then
		cache_media=$link
		fi
		i=$((i+1))
	done
	if $gototub; then
		echo -e "gototub=$gototub\nchoice=$choice\nurl='$url'\ncache_media='$cache_media'\nregex_embed='$regex_embed'\nmedia_links='${media_links[*]}'" > cache.tmp
	else
		echo -e "gototub=$gototub\nchoice=$choice\nurl='$url'\ncache_media='$cache_media'\nregex_embed=\"$regex_embed\"\nmedia_links='${media_links[*]}'" > cache.tmp
	fi
}


reproduce_cache()
{
# Save the variables to reproduce the next episode, and reproduce the episode selected
	rm cache.tmp
	save_cache
	media=$cache_media
	if $gototub; then
		media+="/"
	fi
	reproduce_embedded_link
}


media_english()
{
# Scrape the url to find movies or series
	gototub=true  # Fix bug that episodes in gototub dont reproduce if the url dont end with /
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
		# When series selected, search episodes an change $media to the selected episode
		url_episodes="https://gototub.com/episode/"
		regex_episodes='s_[[:space:]]*<a href="'$url_episodes'([^"]*)">.*_\1_p'
		select_episodes
		url=$url_episodes
		media+="/"  # Fix bug that don't allow to curl if episodes don't end with: /
		choice=$((choice-1))  # Prevent add 2 to choice when saving cache
		save_cache
	fi
	reproduce_embedded_link
}


print_media_titles()
{
	i=1
	for link in ${media_links[*]}
	do
		echo "$i. $link"
		i=$((i+1))
	done
}


media_spanish()
{
# Scrape spanish media
	gototub=false
	url="https://pelisplushd.net/search"
	regex='s_^[[:space:]]*<a href="https:\/\/pelisplushd.net\/([^"]*)" class=.*_\1_p'
	get_url_titles
	url="https://pelisplushd.net/"
	print_media_titles
	get_user_choice
	regex_embed="s_[[:space:]]*video\[[[:digit:]]\] = '([^']*)'.*_\1_p"
	# Distinguis between movie or series
	if [[ $media =~ ^serie\/.* ]]; then
		# When series selected, search episodes an change $media to the selected episode
		url_episodes="https://pelisplushd.net/serie/"
		regex_episodes='s_[[:space:]]*<a href="'$url_episodes'([^"]*)" class=.*_\1_p'
		select_episodes
		url=$url_episodes
		choice=$((choice-1))  # Prevent add 2 to choice when saving cache
		save_cache
	fi
	reproduce_embedded_link
}


hentai_sub_english()
{
# Scrape Hentai
	gototub=false
	url="https://hentaihaven.com/"
	regex='s_<h3><a class="brick-title" href="'$url'series/([^"]*)">.*_\1_p'
	get_url_titles
	print_media_titles
	get_user_choice
	# Since there are only series, change the url to find episodes
	regex_episodes='s_<h3><a class="brick-title" href="'$url'([^"]*)">.*_\1_p'
	url="https://hentaihaven.com/series/"
	select_episodes
	regex_embed='s_<iframe src="([^"]*)".*_\1_p'
	url="https://hentaihaven.com/"
	reproduce_embedded_link
}


menu()
{
	clear
	# If cache found, ask user if want to reproduce next episode
	if [ -e "./cache.tmp" ];then
		source "./cache.tmp"
		read -p "In your last visit you were watching $cache_media, Do you want to see the next episode? Y/N: " ans
		if [ ${ans^^} = "Y" ]; then
			reproduce_cache
		else
			rm cache.tmp
		fi
	fi
	clear
	selected_option=0
	# Print the menu
	while [ $selected_option -ne 5 ]
	do
		echo -e "Menu\n\n1. Watch movies or series in english\n2. Watch movies or series in spanish\n3. Watch Hentai\n5.exit"
		read selected_option
		case $selected_option in
			1)
				media_english
			;;
			2)
				media_spanish
			;;
			3)
				hentai_sub_english
			;;
			5)
				clear
				echo "Goodbye"
				exit
			;;
		esac
	done
}


menu  # This start the menu
