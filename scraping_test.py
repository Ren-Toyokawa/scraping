import os
import urllib.request

from bs4 import BeautifulSoup
#なんか程画質なものも含まれている
#DBと連携する
index = 1
if not os.path.exists("./uesaka_sumire"):
	os.mkdir("./uesaka_sumire")
for num in range(2, 500):
	url = 'https://lineblog.me/uesaka_sumire/?p={0}'.format(num)
	html = urllib.request.urlopen(url)

	soup = BeautifulSoup(html, "html5lib")
	imgs = soup.find_all("img")

	for image in imgs:
		print(image['src'])
		file_name = 'uesaka_sumire/uesaka_sumire{0}.jpg'.format(index)
		command = 'wget -O {0} {1}' .format(file_name, image['src'])
		os.system(command)
		index += 1
