# **COLLEGAMENTO TRA ORACLE XE E SERVER IN HTTP**
Il seguente prototipo ha l'obiettivo di stabilire una connessione tra il database Oracle XE e un server HTTP in seguito ad un trigger.

## **_PREQUISITI <a name='Prerequisiti'></a>_**

Per poter eseguire il progetto, bisogna installare i seguenti componenti:

- Docker;
- L'estensione "Oracle Developer Tools for VS Code" in Visual Studio Code o in alternativa "SqlDeveloper".


## **_INSTALLAZIONE <a name='Installazione'></a>_**

Per poter installare il prototipo ci serviamo di docker compose. Quindi mettendosi nella cartella del progetto dove è presente il file 'docker-compose.yml' lanciare il seguente comando dalla shell:

```bash
docker compose up
```
Compariranno due container all'interno di Docker:
- un container chiamato "server" che rappresenta appunto il server e che stamperà nei log una stringa json relativa alla chiamata http che il db farà al server stesso;
- un container denominato "database" che rappresenta Oracle XE.

## **_COLLEGAMENTO AL DATABASE <a name='Collegamento al DB'></a>_**

Per collegarci al DB usiamo l'estensione "Oracle Developer Tools for VS Code". 
Premendo sul simbolo + in alto a destra, comparirà una schermata come quella seguente:

![create_connection](/immagini_markdown/create_connection.png)

Per connettersi come utente SYS, definire i seguenti parametri:
- Port number: 1548; 
- Role: SYSDBA;
- User name: SYS;
- Password: password. 

Dopodichè premere su "Create Connection" e se i parametri inseriti sono corretti, comparirà "SYS.XEPDB1" sotto la scritta "DATABASE", presente a destra. 


## **_CONFIGURAZIONE ORACLE XE <a name='Configurazione DB'></a>_**

Una volta connessi al DB, bisogna configurare quest'ultimo. Entrando come utente SYS nel DB, lanciare le seguenti query che permettono di creare un utente chiamato "test" la cui password di accesso è "test" e consentono all'utente di potersi connettere al DB:

```sql
CREATE USER test IDENTIFIED BY test;
GRANT CONNECT TO test;
```
A questo punto bisogna creare un ACL (Access Control List) che consenta all'utente di potersi connettere e risolvere una determinata rete. Inoltre l'ACL deve essere assegnata alla rete. Per fare ciò, lanciare le seguenti query:

```sql
BEGIN
  DBMS_NETWORK_ACL_ADMIN.create_acl (
    acl          => 'test_acl_file.xml', 
    description  => 'A test of the ACL functionality',
    principal    => 'TEST',
    is_grant     => TRUE, 
    privilege    => 'connect',
    start_date   => SYSTIMESTAMP,
    end_date     => NULL);
  COMMIT;
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.add_privilege ( 
    acl         => 'test_acl_file.xml', 
    principal   => 'TEST',
    is_grant    => TRUE, 
    privilege   => 'resolve', 
    position    => NULL, 
    start_date  => NULL,
    end_date    => NULL);
  COMMIT;
END;
/


BEGIN
  DBMS_NETWORK_ACL_ADMIN.assign_acl (
    acl         => 'test_acl_file.xml',
    host        => '*', 
    lower_port  => 1,
    upper_port  => 9999); 
  COMMIT;
END;
/
```
Dopo aver fatto ciò, l'utente test deve avere i privilegi per poter usare il pacchetto "UTL_HTTP", creare una tabella e un trigger, modificare le tabelle:

```sql
GRANT EXECUTE ON UTL_HTTP TO test;
grant create table to test;
grant create trigger to test;
ALTER USER test quota unlimited on users;
```

Ora entrare nel DB come utente "test". Per connettersi come utente "test" al DB, eseguire la stessa procedura presente nella sezione "COLLEGAMENTO AL DATABESE", settando i seguenti parametri:
- Port number: 1548; 
- Role: Default;
- User name: TEST;
- Password: test. 

A questo punto lanciare i seguenti comandi come utente "test". Creare una tabella di questo tipo:

```sql
CREATE TABLE PROVA (
        name_1          VARCHAR2(100),
        surname_1 	    VARCHAR2(100),
        id              VARCHAR2(100),
	    time_colum  	TIMESTAMP(6)
    );
```

L'ultima query da lanciare è quella relativa alla creazione del trigger, il quale dopo un evento di INSERT o UPDATE o DELETE fa scattare una chiamata HTTP ad un server, secondo le istruzioni specificate nel trigger stesso:

```sql
CREATE OR REPLACE trigger TRG_EDI_TRANSACTIONS
  AFTER DELETE OR INSERT OR UPDATE on PROVA
  for each row
  WHEN ((OLD.NAME_1 IS NULL AND NEW.TIME_COLUM IS NULL) OR (OLD.NAME_1 IS NOT NULL AND NVL(NEW.TIME_COLUM, TO_DATE('01011900','DDMMYYYY')) = NVL(OLD.TIME_COLUM, TO_DATE('01011900','DDMMYYYY'))) OR NEW.NAME_1 IS NULL)
DECLARE
  l_url            VARCHAR2(50) := 'http://server:8080';
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  msg VARCHAR2(10000);
    BEGIN
        IF DELETING THEN 
            msg := '{"' || :OLD.NAME_1 || '":"' || :OLD.surname_1 || '"}';
        ELSE
            msg := '{"' || :new.NAME_1 || '":"' || :new.surname_1 || '"}';
        END IF;
        DBMS_OUTPUT.PUT_LINE(msg);
        -- Make a HTTP request and get the response.
        l_http_request  := UTL_HTTP.begin_request(l_url, 'POST');
        UTL_HTTP.SET_HEADER( l_http_request, 'User-Agent', 'Mozilla/4.0');
        UTL_HTTP.SET_HEADER( l_http_request, 'Content-Type', 'application/json');
        UTL_HTTP.set_header(l_http_request, 'Content-Length', length(msg));
        UTL_HTTP.SET_HEADER( l_http_request, 'Accept', 'application/json');
        UTL_HTTP.set_header(l_http_request, 'Connection', 'Keep-Alive');
        UTL_HTTP.write_text( l_http_request, msg);
        l_http_response := UTL_HTTP.get_response(l_http_request);
        utl_http.end_response(l_http_response); 
    END TRG_EDI_TRANSACTIONS;
```