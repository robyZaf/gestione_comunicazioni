*** Settings ***
Resource    ../common/common.robot
Library     Collections
Library     String
#Library    RPA.Browser.Selenium    auto_close=${FALSE}


*** Variables ***
${activity_number_in_page}      300
@{MANAGED_CATEGORY}             cambio mail postalizzazione
...                             cambio frequenza pagamento
...                             cambio indirizzo intestatario fattura
...                             cambio modalita pagamento


*** Tasks ***
Gestione Comunicazioni
    Access enErp software
    Open Attivita Assegnato a Operatore
    Put all comunicazioni inside one page
    Iterate over comunicazioni and manage


*** Keywords ***
Access enErp software
    ${enerp_ip}    ${user}    ${password}    Get Secret Enerp
    Open enErp    ${enerp_ip}
    Login enErp    ${user}    ${password}

Open Attivita Assegnato a Operatore
    Click Element When Visible    name:CRM
    Click Element When Visible    xpath=//*[@id="menu"]/div[3]/ul/li[3]/a
    Click Element When Visible    xpath=//*[@id="id_75"]/ul/li[2]/a

Put all comunicazioni inside one page
    Wait Until Element Is Visible    //*[@id="com_pagina_ATTOP"]
    Input Text    //*[@id="com_pagina_ATTOP"]    ${activity_number_in_page}
    Click Button    //*[@id="listaAziende2"]/tfoot/tr/td/input[7]
    Wait Until Element Is Visible    //*[@id="listaAziende2"]

Iterate over comunicazioni and manage
    # iterate over comunicazioni
    FOR    ${index}    IN RANGE    1    ${activity_number_in_page}
        ${exists_another_comunicazione}    Check if exists another comunicazione    ${index}
        IF    ${exists_another_comunicazione}
            Log    Activity number ${index}

            ${categoria}    Retrieve categoria lower case    ${index}
            Log    Categoria: ${categoria}
            #Log To Console    id: ${index} Categoria: ${categoria}

            # open riferimenti (protocollo richiesta)
            Click Link    //*[@id="listaAziende2"]/tbody/tr[${index}]/td[8]/div/a
            # move on new page opened after click
            Switch Window    new
            ${nome_cliente}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[4]/td[2]
            ${p_iva}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[5]/td[2]
            ${cf}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[6]/td[2]
            ${oggetto}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[8]/td[2]
            # close protocollo window
            Click Button    //*[@id="btn_close"]
            Switch Window    main


            Log    Nome cliente: ${nome_cliente}
            Log    P. iva: ${p_iva}
            Log    CF: ${cf}
            Log    Oggetto: ${oggetto}

            Manage comunicazione    ${categoria}

        ELSE
            BREAK
        END
    END

Check if exists another comunicazione
    [Arguments]    ${index}
    ${xpath_comunicazione_to_check}    Set Variable
    ...    /html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]
    ${exists}    RPA.Browser.Selenium.Is Element Visible    xpath=${xpath_comunicazione_to_check}
    RETURN    ${exists}

Manage comunicazione
    [Arguments]    ${categoria}
    TRY
        List Should Contain Value    ${MANAGED_CATEGORY}    ${categoria}
    EXCEPT    .*does not contain value.*    type=regexp
        Log    Categoria: ${categoria} is not managed
        #Log To Console    Categoria: ${categoria} is not managed
    END

Retrieve categoria lower case
    [Arguments]    ${index}
    ${categoria}    RPA.Browser.Selenium.Get Text
    ...    xpath=/html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]/td[7]
    ${categoria_lower}    Convert To Lower Case    ${categoria}
    RETURN    ${categoria_lower}
