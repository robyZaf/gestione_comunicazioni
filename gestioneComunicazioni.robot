*** Settings ***
Resource    ../common/common.robot


*** Variables ***
${activity_number_in_page}=     300


*** Tasks ***
Gestione Comunicazioni
    Access enErp software
    Open Attivita Assegnato a Operatore
    Put all activities inside one page and reload
    Manage activities


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

Manage activities
