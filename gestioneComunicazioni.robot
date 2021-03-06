*** Settings ***
Resource    ../common/common.robot
Library     Collections
Library     String
Library     date_util.py
Library     RPA.Salesforce
#Library    RPA.Browser.Selenium    auto_close=${FALSE}


*** Variables ***
# common variable
${energia}                                  ee
${gas}                                      gas
${activity_number_in_page}                  300
${max_row_to_check_inside_back_office}      50
@{MANAGED_CATEGORY}                         cambio mail postalizzazione
...                                         cambio frequenza pagamento
...                                         anagrafica
...                                         cambio modalita pagamento
#...    rid ko

# cambio frequenza pagamento
@{frequenze_managed}                        mensile    bimestrale    scelta
&{mapping_frequenza_pagamento_select}=      scelta=0    mensile=1    bimestrale=2
&{mapping_mesi_id_checkbox}=                gen=GEN    feb=FEB    mar=MAR    apr=APR
...                                         mag=MAG    giu=GIU    lug=LUG    ago=AGO
...                                         set=SET    ott=OTT    nov=NOV    dic=DIC
...                                         gennaio=GEN    febbraio=FEB    marzo=MAR    aprile=APR
...                                         maggio=MAG    giugno=GIU    luglio=LUG    agosto=AGO
...                                         settembre=SET    ottobre=OTT    novembre=NOV    dicembre=DIC


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
    ${xpath_number_of_activity_per_page}    Set Variable    //*[@id="com_pagina_ATTOP"]
    TRY
        Wait Until Element Is Visible    ${xpath_number_of_activity_per_page}
        Input Text When Element Is Visible    ${xpath_number_of_activity_per_page}    ${activity_number_in_page}
        Click Button When Visible    //*[@id="listaAziende2"]/tfoot/tr/td/input[7]
    EXCEPT    Element '${xpath_number_of_activity_per_page}' not visible after 5 seconds.
        Log    The activities are in single page
    FINALLY
        Wait Until Element Is Visible    //*[@id="listaAziende2"]
    END

Iterate over comunicazioni and manage
    FOR    ${index_comunicazione}    IN RANGE    1    ${activity_number_in_page}
        ${exists_another_comunicazione}    Check if exists another comunicazione    ${index_comunicazione}
        IF    ${exists_another_comunicazione}
            Log    Activity number ${index_comunicazione}

            ${comunicazione_is_managed_correctly}    Manage comunicazione    ${index_comunicazione}
            IF    ${comunicazione_is_managed_correctly}
                Log    OK, Activity number ${index_comunicazione} managed
                #    1. se tutto ?? andato correttamente chiudere segnalazione
                #    2. vedere se bisogna ricaricare pagina o fare altro dopo chiusura segnalazione
            ELSE
                #    vedere se necessario tornare alla pagina iniziale prima di gestire un'altra comunicazione
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

    TRY
        ${categoria}    Retrieve categoria from comunicazione    ${index_comunicazione}
        Log    Categoria: ${categoria}
        #Log To Console    id: ${index_comunicazione} Categoria: ${categoria}

        IF    "${categoria}" == None or len("${categoria}") == 0
            Log    Categoria cannot be empty.
            RETURN    False
        END

        List Should Contain Value    ${MANAGED_CATEGORY}    ${categoria}

        ${cliente}    ${cf}    ${oggetto}    Retrieve information from comunicazione
        ...    ${index_comunicazione}
        Log    Cliente: ${cliente} CF: ${cf} Oggetto: ${oggetto}

        IF    "${oggetto}" == None or len("${oggetto}") == 0
            Log    Oggetto cannot be empty.
            RETURN    False
        END

        # dictionary with field in oggetto
        &{fields_key_pairs}    Create dictionary with fields    ${oggetto}
    EXCEPT    .*does not contain value.*    type=regexp
        Log    Categoria: ${categoria} is not managed
        RETURN    False
    EXCEPT
        RETURN    False
    END

    ############    TODO LIST    ################
    #    Manage comunicazione    ${categoria}
    #    1. check sulle informazioni obbligatorie in base alla categoria
    #    2. se tutte le informazioni sono presenti esegui altrimenti log e continue
    #    3. mapping tra categoria e funzione da eseguire (la funzione si controlla le info?)
    #
    ############    TODO LIST    ################

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
    ${oggetto_lower_case}    Convert To Lower Case    ${oggetto}
    # close window protocollo
    Click Button    //*[@id="btn_close"]
    Switch Window    main
    RETURN    ${cliente}    ${cf}    ${oggetto_lower_case}

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
    # example object    fornitura:EE email:pippo@example.com

    TRY
        ${email}    Set Variable    ${fields_key_pairs}[email]
        ${fornitura}    Set Variable    ${fields_key_pairs}[fornitura]
    EXCEPT    Dictionary .* has no key 'email'.    type=regexp
        Log    Missing required field: email
        #Log To Console    Missing required field: email
        RETURN    False
    EXCEPT    Dictionary .* has no key 'fornitura'.    type=regexp
        Log    Field fornitura not setted, suppose EE and GAS
        #Log To Console    Field fornitura not setted, suppose EE and GAS
        ${fornitura}    Set Variable    all
    EXCEPT
        Log    Something else went wrong
        Log To Console    Something else went wrong
        RETURN    False
    END

    TRY
        IF    "${fornitura}" == "${energia}"
            Open back office EE
            Find cliente and change email address    ${cf}    ${cliente}    ${email}
        ELSE IF    "${fornitura}" == "${gas}"
            Open back office GAS
            Find cliente and change email address    ${cf}    ${cliente}    ${email}
        ELSE
            Open back office EE
            Find cliente and change email address    ${cf}    ${cliente}    ${email}
            Open back office GAS
            Find cliente and change email address    ${cf}    ${cliente}    ${email}
        END
        RETURN    True
    EXCEPT
        Log    Something else went wrong
        RETURN    False
    END

Open back office EE
    Click Element When Visible    name:BACKOFFICE
    Click Element When Visible    //*[@id="menu"]/div[2]/ul/li[2]/a
    Click Element When Visible    //*[@id="id_14"]/ul/li[2]/a

Open back office GAS
    Click Element When Visible    name:BACKOFFICE GAS
    Click Element When Visible    //*[@id="menu"]/div[4]/ul/li[2]/a
    Click Element When Visible    //*[@id="id_97"]/ul/li[2]/a

Find cliente and change email address
    [Arguments]    ${cf}    ${cliente}    ${email}
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
    Switch Window    main

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
    [Arguments]    ${cliente}    ${cf}    &{fields_key_pairs}
    # example object    fornitura:EE frequenza:SCELTA mesi:GEN,MAR,LUG,SET

    TRY
        ${frequenza}    Set Variable    ${fields_key_pairs}[frequenza]
        ${fornitura}    Set Variable    ${fields_key_pairs}[fornitura]

        List Should Contain Value    ${frequenze_managed}    ${frequenza}

        IF    "${frequenza}" == "scelta"
            @{mesi_fattura}    Split String    ${fields_key_pairs}[mesi]    ,
        END
    EXCEPT    Dictionary .* has no key 'frequenza'.    type=regexp
        Log    Missing required field: frequenza
        #Log To Console    Missing required field: frequenza
        RETURN    False
    EXCEPT    .*does not contain value.*    type=regexp
        Log    Frequenza: ${frequenza} is not available
        RETURN    False
    EXCEPT    Dictionary .* has no key 'fornitura'.    type=regexp
        Log    Field fornitura not setted, suppose EE and GAS
        #Log To Console    Field fornitura not setted, suppose EE and GAS
        ${fornitura}    Set Variable    all
    EXCEPT    Dictionary .* has no key 'mesi'.    type=regexp
        Log    Missing required field: mesi
        #Log To Console    Missing required field: mesi
        RETURN    False
    EXCEPT
        Log    Something else went wrong
        Log To Console    Something else went wrong
        RETURN    False
    END

    TRY
        IF    "${fornitura}" == "${energia}"
            Open back office EE
            #filter by CF
            Select From List By Value    id:filtro_ricerca    CODICE_FISCALE
            Input Text When Element Is Visible    id:valore_cercato    ${cf}
            Click Button When Visible    xpath=//*[@id="elencoClienti"]/div/div[1]/input[2]
            ${xpath_scheda_cliente}    Find cliente corretto    ${cliente}
            # open scheda cliente
            Click Link    ${xpath_scheda_cliente}
            Click Element When Visible    //*[@id="td4"]/span

            Find contratto valido and modifica frequenza    ${fornitura}    ${frequenza}    ${mesi_fattura}
        ELSE IF    "${fornitura}" == "${gas}"
            Open back office GAS
            #filter by CF
            Select From List By Value    id:filtro_ricerca    CODICE_FISCALE
            Input Text When Element Is Visible    id:valore_cercato    ${cf}
            Click Button When Visible    xpath=//*[@id="elencoClienti"]/div/div[1]/input[2]
            ${xpath_scheda_cliente}    Find cliente corretto    ${cliente}
            Click Link    ${xpath_scheda_cliente}
            Click Element When Visible    //*[@id="td4"]/span

            Find contratto valido and modifica frequenza    ${fornitura}    ${frequenza}    ${mesi_fattura}
        ELSE
            Open back office EE
            #filter by CF
            Select From List By Value    id:filtro_ricerca    CODICE_FISCALE
            Input Text When Element Is Visible    id:valore_cercato    ${cf}
            Click Button When Visible    xpath=//*[@id="elencoClienti"]/div/div[1]/input[2]
            ${xpath_scheda_cliente}    Find cliente corretto    ${cliente}
            Click Link    ${xpath_scheda_cliente}
            Click Element When Visible    //*[@id="td4"]/span
            Find contratto valido and modifica frequenza    ${energia}    ${frequenza}    ${mesi_fattura}

            Open back office GAS
            #filter by CF
            Select From List By Value    id:filtro_ricerca    CODICE_FISCALE
            Input Text When Element Is Visible    id:valore_cercato    ${cf}
            Click Button When Visible    xpath=//*[@id="elencoClienti"]/div/div[1]/input[2]
            ${xpath_scheda_cliente}    Find cliente corretto    ${cliente}
            Click Link    ${xpath_scheda_cliente}
            Click Element When Visible    //*[@id="td4"]/span
            Find contratto valido and modifica frequenza    ${gas}    ${frequenza}    ${mesi_fattura}
        END
        RETURN    True
    EXCEPT
        Log    Something else went wrong
        RETURN    False
    END

Find contratto valido and modifica frequenza
    [Arguments]    ${back_office_type}    ${frequenza}    ${mesi_fattura}
    #retrieve inizio e fine validita e check se data di oggi ?? all'interno
    ${today_date}    Today Dmy
    FOR    ${contract_row}    IN RANGE    1    ${max_row_to_check_inside_back_office}    2
        # Log To Console    number: ${contract_row}

        ${inizio_validita_contratto}    RPA.Browser.Selenium.Get Text
        ...    //*[@id="listaAziende4"]/tbody/tr[${contract_row}]/td[3]
        ${fine_validita_contratto}    RPA.Browser.Selenium.Get Text
        ...    //*[@id="listaAziende4"]/tbody/tr[${contract_row}]/td[4]

        ${contratto_in_corso_validita}    Is Date Include Between
        ...    ${inizio_validita_contratto}
        ...    ${fine_validita_contratto}
        ...    ${today_date}
        ...    %d/%m/%Y

        IF    ${contratto_in_corso_validita}
            Click Element When Visible    //*[@id="listaAziende4"]/tbody/tr[${contract_row}]/td[12]/a
            ${index_row_modifica_contratto}    Evaluate    ${contract_row} + 1
            IF    "${back_office_type}" == "${energia}"
                Click Element When Visible
                ...    xpath=/html/body/div[2]/div[5]/div[3]/div/div[2]/div/div[4]/div[4]/table/tbody/tr[${index_row_modifica_contratto}]/td[2]/input[1]
            ELSE
                Click Element When Visible
                ...    xpath=/html/body/div[2]/div[5]/div[3]/div/div[2]/div/div[4]/div[3]/table/tbody/tr[${index_row_modifica_contratto}]/td[2]/input[1]
            END

            Switch Window    new
            Click Element When Visible    //*[@id="td4"]/span

            Select From List By Value    id:ID_FREQUENZA    &{mapping_frequenza_pagamento_select}[${frequenza}]
            IF    "${frequenza}" == "scelta"
                FOR    ${mese}    IN    @{mesi_fattura}
                    Select Checkbox    id:${mese}
                END
            END
            Click Element When Visible    //*[@id="invia"]
            Switch Window    main
        END
    END

Modifica anagrafica
    [Arguments]    ${cliente}    ${cf}    ${fields_key_pairs}
    #TODO example object    fornitura:GAS comune:ROMA indirizzo:VIA VENETO num:23 cap:90465

    #TRY
    #    ${comune}    Set Variable    ${fields_key_pairs}[comune]
    #    ${indirizzo}    Set Variable    ${fields_key_pairs}[indirizzo]
    #    ${fornitura}    Set Variable    ${fields_key_pairs}[fornitura]
#
    #    List Should Contain Value    ${frequenze_managed}    ${frequenza}
#
    #    IF    "${frequenza}" == "scelta"
    #    @{mesi_fattura}    Split String    ${fields_key_pairs}[mesi]    ,
    #    END
    #EXCEPT    Dictionary .* has no key 'frequenza'.    type=regexp
    #    Log    Missing required field: frequenza
    #    #Log To Console    Missing required field: frequenza
    #    RETURN    False
    #EXCEPT    .*does not contain value.*    type=regexp
    #    Log    Frequenza: ${frequenza} is not available
    #    RETURN    False
    #EXCEPT    Dictionary .* has no key 'fornitura'.    type=regexp
    #    Log    Field fornitura not setted, suppose EE and GAS
    #    #Log To Console    Field fornitura not setted, suppose EE and GAS
    #    ${fornitura}    Set Variable    all
    #EXCEPT    Dictionary .* has no key 'mesi'.    type=regexp
    #    Log    Missing required field: mesi
    #    #Log To Console    Missing required field: mesi
    #    RETURN    False
    #EXCEPT
    #    Log    Something else went wrong
    #    Log To Console    Something else went wrong
    #    RETURN    False
    #END
    #RETURN    True

    #####################    Manage comune    ####################
    TRY
        IF    "${fornitura}" == "${energia}"
            Open back office EE
            #filter by CF
            Select From List By Value    id:filtro_ricerca    CODICE_FISCALE
            Input Text When Element Is Visible    id:valore_cercato    ${cf}
            Click Button When Visible    xpath=//*[@id="elencoClienti"]/div/div[1]/input[2]
            ${xpath_scheda_cliente}    Find cliente corretto    ${cliente}
            # open scheda cliente
            Click Link    ${xpath_scheda_cliente}
            Click Button When Visible    //*[@id="schedaCliente"]/div/div/input[1]
            Switch Window    new
            ${comune_upper}    Convert To Upper Case    ${comune}
            Input Text When Element Is Visible    id:COMUNE    ${comune_upper}
            # wait query result
            Wait Until Element Is Visible    xpath=/html/body/div[5]    timeout=10
            # cycle to find comune corretto
            ${regex_to_extract_comune}    Set Variable    (.*)\\s\\(\\w{2}\\)
            ${index_result}    Set Variable    ${1}
            ${xpath_list_element}    Set variable    /html/body/div[5]/ul/li[${index_result}]
            ${exists_another_result}    RPA.Browser.Selenium.Is Element Visible
            ...    xpath=${xpath_list_element}
            WHILE    ${exists_another_result}
                ${current_comune}    RPA.Browser.Selenium.Get Text    xpath=${xpath_list_element}
                ${group_match_comune}    Get Regexp Matches
                ...    ${current_comune}
                ...    ${regex_to_extract_comune}
                ...    1
                ${comune_without_provincia}    Set Variable    ${group_match_comune}[0]
                #Log To Console    ${comune_without_provincia}
                IF    "${comune_without_provincia}" == "${comune_upper}"
                    Click Element If Visible    xpath=${xpath_list_element}
                    BREAK
                END
                # increase variable for next step
                ${index_result}    Evaluate    ${index_result} + 1
                ${xpath_list_element}    Set variable    /html/body/div[5]/ul/li[${index_result}]
                ${exists_another_result}    RPA.Browser.Selenium.Is Element Visible
                ...    xpath=${xpath_list_element}
            END

            # inserimento indirizzo e civico come testi normali
            Input Text When Element Is Visible    id:INDIRIZZO    ${indirizzo}
            Input Text When Element Is Visible    id:CIVICO    ${civico}

            # considerare il cap per un confronto?

            Click Button When Visible    id:button_salva
            Switch Window    main

            # modifica dati cliente
            #### TODO
        ELSE IF    "${fornitura}" == "${gas}"
            Open back office GAS
            #filter by CF

            # modifica dati cliente
            #### TODO
        ELSE
            Open back office EE
            #filter by CF

            # modifica dati cliente
            #### TODO

            Open back office GAS
            #filter by CF

            # modifica dati cliente
            #### TODO
        END
        RETURN    True
    EXCEPT
        Log    Something else went wrong
        RETURN    False
    END
    ##############################################################

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
