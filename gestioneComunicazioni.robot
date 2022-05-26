*** Settings ***
Resource    ../common/common.robot


*** Variables ***
${activity_number_in_page}      300


*** Tasks ***
Gestione Comunicazioni
    Access enErp software
    Open Attivita Assegnato a Operatore
    Put all activities inside one page and reload
    Iterate over activities and manage it


*** Keywords ***
Access enErp software
    ${enerp_ip}    ${user}    ${password}    Get Secret Enerp
    Open enErp    ${enerp_ip}
    Login enErp    ${user}    ${password}

Open Attivita Assegnato a Operatore
    Click Element When Visible    name:CRM
    Click Element When Visible    xpath=//*[@id="menu"]/div[3]/ul/li[3]/a
    Click Element When Visible    xpath=//*[@id="id_75"]/ul/li[2]/a

Put all activities inside one page and reload
    Wait Until Element Is Visible    //*[@id="com_pagina_ATTOP"]
    Input Text    //*[@id="com_pagina_ATTOP"]    ${activity_number_in_page}
    Click Button    //*[@id="listaAziende2"]/tfoot/tr/td/input[7]

Iterate over activities and manage it
    # iterate over activities
    FOR    ${index}    IN RANGE    1    ${activity_number_in_page}
        ${xpath_activity_to_check}    Set Variable
        ...    /html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]
        ${exists_another_activity}    RPA.Browser.Selenium.Is Element Visible    xpath=${xpath_activity_to_check}
        IF    ${exists_another_activity}
            Log    Activities number ${index}
        ELSE
            BREAK
        END
    END

#Check if exists another activity
#    [Arguments]    ${index}
#    ${xpath_row_to_check}    Set Variable
#    ...    /html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index}]
#    ${exists}    RPA.Browser.Selenium.Is Element Visible    xpath=${xpath_row_to_check}
#    RETURN    ${exists}
