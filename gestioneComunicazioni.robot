*** Settings ***
Resource    ../common/common.robot
Library     Collections
Library     String
#Library    RPA.Browser.Selenium    auto_close=${FALSE}


*** Variables ***
${activity_number_in_page}                  300
${max_row_to_check_inside_back_office}      50
@{MANAGED_CATEGORY}                         cambio mail postalizzazione
...                                         cambio frequenza pagamento
...                                         anagrafica
...                                         cambio modalita pagamento
#...    rid ko


*** Tasks ***
Gestione Comunicazioni
    Access enErp software
    Open Attivita Assegnato a Operatore
    Put all comunicazioni inside one page
    #Iterate over comunicazioni and manage


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

    IF    "${categoria}" == None or len("${categoria}") == 0
        Log    Categoria cannot be empty.
        RETURN    False
    END

    ${cliente}    ${cf}    ${oggetto}    Retrieve information from comunicazione
    ...    ${index_comunicazione}
    Log    Cliente: ${cliente} CF: ${cf} Oggetto: ${oggetto}

    IF    "${oggetto}" == None or len("${oggetto}") == 0
        Log    Oggetto cannot be empty.
        RETURN    False
    END
    #${categoria_is_managed}    Check if categoria is managed    ${categoria}
    #IF    ${categoria_is_managed}
    #    Log    Categoria: ${categoria}
    #ELSE
    #CONTINUE
    #END

    # dictionary with field in oggetto
    &{fields_key_pairs}    Create dictionary with fields    ${oggetto}

    ${is_comunicazione_correctly_managed}    Set Variable    False
    IF    "${categoria}" == "cambio mail postalizzazione"
        ${is_comunicazione_correctly_managed}    Cambio mail postalizzazione
        ...    ${cliente}
        ...    ${cf}
        ...    &{fields_key_pairs}
    ELSE IF    "${categoria}" == "cambio frequenza pagamento"
        ${is_comunicazione_correctly_managed}    Cambio frequenza pagamento
        ...    ${cliente}
        ...    ${cf}
        ...    &{fields_key_pairs}
    ELSE IF    "${categoria}" == "anagrafica"
        ${is_comunicazione_correctly_managed}    Modifica anagrafica
        ...    ${cliente}
        ...    ${cf}
        ...    &{fields_key_pairs}
    ELSE IF    "${categoria}" == "cambio modalita pagamento"
        ${is_comunicazione_correctly_managed}    Cambio modalita pagamento
        ...    ${cliente}
        ...    ${cf}
        ...    &{fields_key_pairs}
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
    ${cf}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[6]/td[2]
    ${oggetto}    RPA.Browser.Selenium.Get Text    //*[@id="pageContent"]/table/tbody/tr[8]/td[2]
    # close window protocollo
    Click Button    //*[@id="btn_close"]
    Switch Window    main
    RETURN    ${cliente}    ${cf}    ${oggetto}

Create dictionary with fields
    [Arguments]    ${oggetto}
    @{fields}    Split String    ${oggetto}
    &{fields_dict}    Create Dictionary
    FOR    ${field}    IN    @{fields}
        @{key_value}    Split String    ${field}    separator=:
        Set To Dictionary    ${fields_dict}    ${key_value}[0]    ${key_value}[1]
    END
    RETURN    ${fields_dict}

Cambio mail postalizzazione
    [Arguments]    ${cliente}    ${cf}    &{fields_key_pairs}
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

    # Check if mandatory fields are in the object
    TRY
        ${email}    Set Variable    ${fields_key_pairs}[email]
        ${fornitura}    Set Variable    ${fields_key_pairs}[fornitura]

        # TBD
        # RETURN    True
    EXCEPT    Dictionary .* has no key 'email'.    type=regexp
        Log    Missing required field: email
        #Log To Console    Missing required field: email
        RETURN    False
    EXCEPT    Dictionary .* has no key 'fornitura'.    type=regexp
        Log    Field fornitura not setted, suppose EE and GAS
        #Log To Console    Field fornitura not setted, suppose EE and GAS
        ${fornitura}    Set Variable    ALL
    EXCEPT
        Log    Something else went wrong
        Log To Console    Something else went wrong
        RETURN    False
    END

    TRY
        IF    ${fornitura} == EE
            #Open back office EE and do operation
            Click Element When Visible    name:BACKOFFICE
            Click Element When Visible    xpath=//*[@id="menu"]/div[2]/ul/li[2]/a
            Click Element When Visible    xpath=//*[@id="id_14"]/ul/li[2]/a
            #filter by CF
            Select From List By Value    id:filtro_ricerca    CODICE_FISCALE
            Input Text When Element Is Visible    id:valore_cercato    ${cf}
            Click Button When Visible    xpath=//*[@id="elencoClienti"]/div/div[1]/input[2]
            ${xpath_scheda_cliente}    Find cliente corretto    ${cliente}
            # open scheda cliente
            Click Link    ${xpath_scheda_cliente}
            # go to Tab Contatti cliente
            Click Element When Visible    //*[@id="td3"]/span
            # modify indirizzo email spedizione
            Click Element When Visible    //*[@id="listaAziende"]/tbody/tr[3]/td[10]/a
            Switch Window    new
            Input Text When Element Is Visible    id:EMAIL    ${email}
            RPA.Browser.Selenium.Press Keys    None    TAB
            Click Button When Visible    id:salva_modifica_contatto_sped
        ELSE IF    ${fornitura} == GAS
            #Open back office GAS and do operation
            Click Element When Visible    name:BACKOFFICE GAS
        ELSE
            #Open back office EE and do operation
            Click Element When Visible    name:BACKOFFICE

            #Open back office GAS and do operation
            Click Element When Visible    name:BACKOFFICE GAS
        END
    EXCEPT
        Log    Something went wrong
        RETURN    False
    END

    #Log    fornitura: ${fornitura}
    #Log To Console    fornitura: ${fornitura}

Find cliente corretto
    [Arguments]    ${nome_cliente}
    FOR    ${row_cliente}    IN RANGE    1    ${max_row_to_check_inside_back_office}
        # Log To Console    number: ${row_cliente}

        ${xpath_scheda_cliente}    Set Variable    //*[@id="listaAziendeD"]/tbody/tr[${row_cliente}]/td[1]/a
        # take ragione sociale
        ${ragione_sociale}    RPA.Browser.Selenium.Get Text    ${xpath_scheda_cliente}
        IF    "${ragione_sociale}" == "${nome_cliente}"
            RETURN    ${xpath_scheda_cliente}
        ELSE
            CONTINUE
        END
    END

Cambio frequenza pagamento
    [Arguments]    ${cliente}    ${cf}    ${oggetto}
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
    #TODO
    RETURN    True

Modifica anagrafica
    [Arguments]    ${cliente}    ${cf}    ${oggetto}
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
    #TODO
    RETURN    True

Cambio modalita pagamento
    [Arguments]    ${cliente}    ${cf}    ${oggetto}
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
    #TODO
    RETURN    True
