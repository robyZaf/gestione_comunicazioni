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
#...    rid ko

#${COMMON_OPTIONAL_FIELD_FORNITURA}    fornitura
#@{MANDATORY_FIELD_CAMBIO_MAIL_POSTALIZZAZIONE}    email
#@{MANDATORY_FIELD_CAMBIO_FREQUENZA_PAGAMENTO}    frequenza
#@{MANDATORY_FIELD_CAMBIO_INDIRIZZO_INTESTATARIO_FATTURA}    email
#@{MANDATORY_FIELD_CAMBIO_MODALITA_PAGAMENTO}    email
#&{DICTIONARY}    cambio mail postalizzazione=@{MANDATORY_FIELD_CAMBIO_MAIL_POSTALIZZAZIONE}
#...    cambio frequenza pagamento=@{MANDATORY_FIELD_CAMBIO_FREQUENZA_PAGAMENTO}
#...    cambio indirizzo intestatario fattura=@{MANDATORY_FIELD_CAMBIO_INDIRIZZO_INTESTATARIO_FATTURA}
#...    cambio modalita pagamento=@{MANDATORY_FIELD_CAMBIO_MODALITA_PAGAMENTO}


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
    FOR    ${index_comunicazione}    IN RANGE    1    ${activity_number_in_page}
        ${exists_another_comunicazione}    Check if exists another comunicazione    ${index_comunicazione}
        IF    ${exists_another_comunicazione}
            Log    Activity number ${index_comunicazione}

            ${comunicazione_is_managed_correctly}    Manage comunicazione    ${index_comunicazione}
            IF    ${comunicazione_is_managed_correctly}
                Log    OK, Activity number ${index_comunicazione} managed
                #    1. se tutto è andato correttamente chiudere segnalazione
                #    2. vedere se bisogna ricaricare pagina o fare altro dopo chiusura segnalazione
            ELSE
                CONTINUE
            END
        ELSE
            BREAK
        END
    END

Check if exists another comunicazione
    [Arguments]    ${index_comunicazione}
    ${xpath_comunicazione_to_check}    Set Variable
    ...    /html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index_comunicazione}]
    ${exists}    RPA.Browser.Selenium.Is Element Visible    xpath=${xpath_comunicazione_to_check}
    RETURN    ${exists}

#Check if categoria is managed
#    [Arguments]    ${categoria}
#    TRY
#    List Should Contain Value    ${MANAGED_CATEGORY}    ${categoria}
#    RETURN    True
#    EXCEPT    .*does not contain value.*    type=regexp
#    Log    Categoria: ${categoria} is not managed
#    RETURN    False
#    #Log To Console    Categoria: ${categoria} is not managed
#    END

Manage comunicazione
    [Arguments]    ${index_comunicazione}

    ${categoria}    Retrieve categoria from comunicazione    ${index_comunicazione}
    Log    Categoria: ${categoria}
    #Log To Console    id: ${index_comunicazione} Categoria: ${categoria}

    ${cliente}    ${p_iva}    ${cf}    ${oggetto}    Retrieve information from comunicazione
    ...    ${index_comunicazione}
    Log    Nome cliente: ${cliente} P. iva: ${p_iva} CF: ${cf} Oggetto: ${oggetto}

    #${categoria_is_managed}    Check if categoria is managed    ${categoria}
    #IF    ${categoria_is_managed}
    #    Log    Categoria: ${categoria}
    #ELSE
    #CONTINUE
    #END

    ${is_comunicazione_correctly_managed}    Set Variable    False
    IF    "${categoria}" == "cambio mail postalizzazione"
        ${is_comunicazione_correctly_managed}    Cambio mail postalizzazione
        ...    ${cliente}
        ...    ${p_iva}
        ...    ${cf}
        ...    ${oggetto}
    ELSE IF    "${categoria}" == "cambio frequenza pagamento"
        ${is_comunicazione_correctly_managed}    Cambio frequenza pagamento
        ...    ${cliente}
        ...    ${p_iva}
        ...    ${cf}
        ...    ${oggetto}
    ELSE IF    "${categoria}" == "cambio indirizzo intestatario fattura"
        ${is_comunicazione_correctly_managed}    Cambio indirizzo intestatario fattura
        ...    ${cliente}
        ...    ${p_iva}
        ...    ${cf}
        ...    ${oggetto}
    ELSE IF    "${categoria}" == "cambio modalita pagamento"
        ${is_comunicazione_correctly_managed}    Cambio modalita pagamento
        ...    ${cliente}
        ...    ${p_iva}
        ...    ${cf}
        ...    ${oggetto}
    ELSE
        Log    Categoria: ${categoria} not managed
    END
    RETURN    ${is_comunicazione_correctly_managed}

Retrieve categoria from comunicazione
    [Arguments]    ${index_comunicazione}
    ${categoria}    RPA.Browser.Selenium.Get Text
    ...    xpath=/html/body/div[2]/div[5]/div[3]/div/div/div[2]/form/table/tbody/tr[${index_comunicazione}]/td[7]
    ${categoria_lower}    Convert To Lower Case    ${categoria}
    RETURN    ${categoria_lower}

Retrieve information from comunicazione
    [Arguments]    ${index_comunicazione}
    # open riferimenti (protocollo richiesta)
    Click Link    //*[@id="listaAziende2"]/tbody/tr[${index_comunicazione}]/td[8]/div/a
    # move on new page opened after click
    Switch Window    new
    ${cliente}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[4]/td[2]
    ${p_iva}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[5]/td[2]
    ${cf}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[6]/td[2]
    ${oggetto}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[8]/td[2]
    # close window protocollo
    Click Button    //*[@id="btn_close"]
    Switch Window    main
    RETURN    ${cliente}    ${p_iva}    ${cf}    ${oggetto}

Cambio mail postalizzazione
    [Arguments]    ${cliente}    ${p_iva}    ${cf}    ${oggetto}
    #TODO example object    fornitura:EE email:pippo@example.com
    #    1. check campi obbligatori
    #    2. if i campi sono ok, prosegui, altrimenti log e return false
    ############    TODO LIST    ################
    #    Manage comunicazione    ${categoria}
    #    1. check sulle informazioni obbligatorie in base alla categoria
    #    2. se tutte le informazioni sono presenti esegui altrimenti log e continue
    #    3. mapping tra categoria e funzione da eseguire (la funzione si controlla le info?)
    #
    ############    TODO LIST    ################
    #return true if ok else false
    &{fields_key_pairs}    Create dictionary with fields    ${oggetto}

    # crea un dictionary
    Check if mandatory fields are in the object
    IF    ${var1} == ${var1}
        Call Keyword
        RETURN    True
    ELSE
        Log    Missing required field for categoria: cambio mail postalizzazione
        RETURN    False
    END

Cambio frequenza pagamento
    [Arguments]    ${cliente}    ${p_iva}    ${cf}    ${oggetto}
    @{res}    Split String    ${oggetto}
    #TODO
    RETURN    True

Cambio indirizzo intestatario fattura
    [Arguments]    ${cliente}    ${p_iva}    ${cf}    ${oggetto}
    @{res}    Split String    ${oggetto}
    #TODO
    RETURN    True

Cambio modalita pagamento
    [Arguments]    ${cliente}    ${p_iva}    ${cf}    ${oggetto}
    @{res}    Split String    ${oggetto}
    #TODO
    RETURN    True

Create dictionary with fields
    [Arguments]    ${oggetto}
    @{fields}    Split String    ${oggetto}
    &{fields_dict}    Create Dictionary
    FOR    ${field}    IN    @{fields}
        @{key_value}    Split String    ${field}    separator=:
        Set To Dictionary    ${fields_dict}    ${key_value}[0]    ${key_value}[1]
    END
    RETURN    ${fields_dict}
