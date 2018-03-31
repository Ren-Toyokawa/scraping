import urllib.request
from bs4 import BeautifulSoup

url = "http://www.lumine.ne.jp/gloabal_search/search/search_result.php?mode=b&mansion_id=98&cat_type=2&search[17]=00013&search[18]=00014&search[19]=00015&search[20]=00016&search[21]=00017"
html = urllib.request.urlopen(url)

soup = BeautifulSoup(html, "html5lib")
shop_list = soup.find(class_="shopList")

trs = shop_list.find_all("tr")

for tr in trs:
	if tr.find_all("td") != None:
		for td in tr.find_all("td"):
			if td.a != None:
				print(td.a.string,end="\t")
			else:
				print(td.string,end="\t")
		print("")
