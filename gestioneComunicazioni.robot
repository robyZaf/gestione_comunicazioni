*** Settings ***
Resource    ../common/common.robot
Library     Collections
#Library    RPA.Browser.Selenium    auto_close=${FALSE}


*** Variables ***
${activity_number_in_page}      300
@{MANAGED_CATEGORY}             CAMBIO MAIL POSTALIZZAZIONE
...                             CAMBIO FREQUENZA PAGAMENTO
...                             CAMBIO INDIRIZZO INTESTATARIO FATTURA
...                             CAMBIO MODALITA PAGAMENTO


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
            Manage comunicazione    ${index}

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
    [Arguments]    ${index}
    # retrieve categoria
    ${categoria}    Retrieve categoria    ${index}
    Log    Categoria: ${categoria}
    #Log To Console    id: ${index} Categoria: ${categoria}
    TRY
        List Should Contain Value    ${MANAGED_CATEGORY}    ${categoria}
    EXCEPT    .*does not contain value.*    type=regexp
        Log To Console    Categoria: ${categoria} is not managed
    END

Retrieve categoria
    [Arguments]    ${index}
    ${categoria}    RPA.Browser.Selenium.Get Text
    ...    xpath=/html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]/td[7]
    RETURN    ${categoria}
