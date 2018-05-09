import time
import re
import firebase_admin


from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from firebase_admin import credentials
from firebase_admin import firestore

def is_carilie_sumurry(aside):
    for div in aside.find_elements_by_tag_name('div'):
        if div.text == 'カロリー・栄養一覧':
            return True


def get_calorie_link_sumurry(driver):
    asides = driver.find_elements_by_class_name('sidebar')
    link_list = []
    for aside in asides:
        #asideの中には、不要な項目も混ざっているため、カロリー一覧のコンテンツのみを取得する。
        if is_carilie_sumurry(aside):
            a_list = aside.find_element_by_class_name('menuContents').find_elements_by_tag_name('a')
            for a in a_list:
                link_list.append(a.get_attribute('href'))
    return link_list

# 種類ごとの全1覧ページを取得する
def get_all_summury_pages_from_type(link_list,driver):
    food_material_pages = []
    for link in link_list:
        #pageのURLを保持しておく
        # links先に繊維する
        driver.get(link)
        print(driver.title)
        last = driver.find_element_by_link_text('Last')
        last_page_link = last.get_attribute('href')
        #Lastのページ数のみを取得する。
        pattern = r"\d*$"
        lim = 0
        match_obj = re.search(pattern,last_page_link)
        if match_obj:
            lim = match_obj.group()
            
        #総page数を取得
        for index in range(1,int(lim)):
            page_url = link + str(index)
            food_material_pages.append(page_url)
        
    return food_material_pages 

def get_food_material_page_link(link_list,driver):
    food_material_page_list = []
    # 種類ごとの全1覧ページを取得する
    all_summury_pages_from_type = get_all_summury_pages_from_type(link_list,driver)

    for food_type_page in all_summury_pages_from_type:
        driver.get(food_type_page)
        soshoku_a_list = driver.find_elements_by_class_name('soshoku_a')
        for food_material_page in soshoku_a_list:
            food_material_page_list.append(food_material_page.get_attribute('href'))
    
    return food_material_page_list


def parse_food_material_page(driver,food_material_pages):
    cred = credentials.Certificate('/Users/toyokawaren/GitHub/py_scraping/calorie.slism.jp/DietMenu-bbec33de6b70.json')
    firebase_admin.initialize_app(cred)
        
    db = firestore.client()
    for food_material_page in food_material_pages:
        
        #
        food_material = {u"image":'',u"color":''}
        
        #ページに遷移
        driver.get(food_material_page)
        
        food_material_name = driver.find_element_by_xpath('//h1[@class="ccdsSingleHl01"]').text
        print(food_material_name)
        food_material[u'name'] = food_material_name
        
        food_material.update(append_nutrytion('//div[@id="mainData"]/table//tr'))
        food_material.update(append_nutrytion('//div[@id="vitamin"]/table//tr'))
        food_material.update(append_nutrytion('//div[@id="mineral"]/table//tr'))

        doc_ref = db.collection(u'food_materials').document()
        doc_ref.set(food_material)


def append_nutrytion(element_name):
    lim = len(driver.find_elements_by_xpath(element_name))
    food_material = {}
    for index in range(1,lim):
        tr = driver.find_element_by_xpath(element_name +'['+str(index)+']')
        if tr.text != '':
            td_list = tr.find_elements_by_tag_name('td')
            column_name = convert_colum_name(td_list[0].text)
            
            value = re.sub(r'\(.*\)','',td_list[1].text)
            quantity, unit = split_into_quantity_and_unit(value)
            nutrition_value ={u'amount':quantity,u'unit':unit}
            food_material[column_name] = nutrition_value
            
    return food_material


def split_into_quantity_and_unit(value):
    quantity = re.search(r'\d*(\.|)\d*',value).group(0)
    unit = re.search(r'([a-z]|μ)+',value).group(0)
    return quantity,convert_unit_type(unit)


#"mineral": mineral?.dictionary ?? "",
#"biotin": biotin?.dictionary ?? "",
#"glycemicIndex": glycemicIndex ?? 0
def convert_colum_name(nutrition_name):

    if nutrition_name == 'エネルギー':
        return u'calories'
    elif nutrition_name == 'タンパク質':
        return u'protein'
    elif nutrition_name == '脂質':
        return u'lipid'
    elif nutrition_name == '炭水化物':
        return u'carbohydrate'
    elif nutrition_name == 'ビタミンA':
        return u'vitamin_A'
    elif nutrition_name == 'ビタミンD':
        return u'vitamin_D'
    elif nutrition_name == 'ビタミンE':
        return u'vitamin_E'
    elif nutrition_name == 'ビタミンK':
        return u'vitamin_K'
    elif nutrition_name == 'ビタミンB1':
        return u'vitamin_B1'
    elif nutrition_name == 'ビタミンB2':
        return u'vitamin_B2'
    elif nutrition_name == 'ビタミンB6':
        return u'vitamin_B6'
    elif nutrition_name == 'ビタミンB12':
        return u'vitamin_B12'    	
    elif nutrition_name == 'ナイアシン':
        return u'niacin'
    elif nutrition_name == '葉酸':
        return u'folic_acid'
    elif nutrition_name == 'パントテン酸':
        return u'pantothenic_acid'
    elif nutrition_name == 'ビタミンC':
        return u'vitamin_C'
    elif nutrition_name == '食物繊維 総量':
        return u'dietary_fiber'
    elif nutrition_name == 'ナトリウム':
        return u'sodium'
    elif nutrition_name == 'カリウム':
        return u'potassium'
    elif nutrition_name == 'カルシウム':
        return u'calcium'
    elif nutrition_name == 'マグネシウム':
        return u'magnesium'
    elif nutrition_name == 'リン':
        return u'rin'
    elif nutrition_name == '鉄':
        return u'iron'
    elif nutrition_name == '亜鉛':
        return u'iron zinc'
    elif nutrition_name == '銅':
        return u'copper'
    elif nutrition_name == 'マンガン':
        return u'manganese'
    elif nutrition_name == 'モリブデン':
        return u'molybdenum'
    else:
        return u'unknown'

def convert_unit_type(unit):
    if unit =='fg':
        return 1
    elif unit =='pg':
         return 2
    elif unit =='ng':
        return 3
    elif unit =='μg':
         return 4
    elif unit =='mg':
        return 5
    elif unit =='g':
        return 6
    elif unit == 'kcal':
        return 10


start = time.time()
options = Options()
# Chromeのパス（Stableチャネルで--headlessが使えるようになったら不要なはず）
# options.binary_location = '/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary'
# ヘッドレスモードを有効にする（次の行をコメントアウトすると画面が表示される）。
options.add_argument('--headless')
# ChromeのWebDriverオブジェクトを作成する。
driver = webdriver.Chrome(chrome_options=options)
# http://calorie.slism.jp/ を開く
driver.get('http://calorie.slism.jp/')
time.sleep(2)  # Chromeの場合はAjaxで遷移するので、とりあえず適当に2秒待つ。

# topページから食品カテゴリのリンクリストを取得する
link_list = get_calorie_link_sumurry(driver)

#食品カテゴリのリンクリストを使用して遷移し、食材のページURLを取得する
food_material_pages = get_food_material_page_link(link_list,driver)

#pageを解析し、栄養素を取得する
parse_food_material_page(driver, food_material_pages)
#parse_food_material_page_old()

elapsed_time = time.time() - start
print("data :{0}".format(len(food_material_pages)))
print ("elapsed_time:{0}".format(elapsed_time) + "[sec]")

driver.quit()  # ブラウザーを終了する。