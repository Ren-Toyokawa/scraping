class EDINET:
    def input_value_by_id(browser, element_id, value):
        element_name = browser.find_element_by_id(element_id)
        element_name.clear
        element_name.send_keys(value)

    def open_financial_stattements(browser, tr):
        tds = tr.find_elements_by_tag_name('td')
        #列:提出書類のみを取得する
        link = tds[1].find_element_by_tag_name('a')
        print(link.text)
        #click した場合、別Windowで取得される
        link.click()

    def batch_parse_financial_statements(browser):
        FILENAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screen")
        current_window = browser.current_window_handle
        index = 1
        for window in browser.window_handles:
            browser.switch_to_window(window)
            print(FILENAME + '_' + str(index) +'.png')
            browser.save_screenshot(FILENAME + '_' + str(index) +'.png')
            parse_financial_statements(browser)
            browser.switch_to_window(current_window)
            index += 1

    def parse_financial_statements(browser):
        print('start parse_financial_statements')

        if this_window_is_document_search(browser):
            print('書類検索画面はスキップ')
            return None
    
        #frameを切り変える
        browser.switch_to_frame('viewFrame')
        browser.switch_to_frame('menuFrame2')

        anchor_list = browser.find_elements_by_tag_name('a')
    
        #貸借対照表
        parse_balance_sheet(browser, anchor_list)
        #損益計算書
        #キャッシュフロー計算書
        #株式指標


    #document 書類
    def this_window_is_document_search(browser):
        for h2 in browser.find_elements_by_tag_name('h2'):
            if h2.text == '書類簡易検索結果（一覧）画面':
                return True


    # 貸借対照表を解析する
    def parse_balance_sheet(browser, anchor_list):
        FILENAME = os.path.join(os.path.dirname(os.path.abspath(__file__)), "save.html")
        for a in anchor_list:
            if '経理の状況' in a.text:
                print(a.text)
                a.click()
                #fram の移動ができない
                # viewFrame -> menuFrmae2 -> mainFrame  は無理？
                #print(browser.page_source)
                #f = open(FILENAME,'w')
                #f.write(browser.page_source)