CREATE OR REPLACE TRIGGER prova_audit_trg
    AFTER
    INSERT
    ON PROVA
    FOR EACH ROW
DECLARE
   l_transaction VARCHAR2(10);
BEGIN
   -- determine the transaction type
   l_transaction := CASE
         WHEN INSERTING THEN 'INSERT'
   END;

   -- insert a row into the audit table
   INSERT INTO PROVA2 (NAME_1, SURNAME_1, ID, TRANSACTION_TYPE)
   VALUES (NAME_1, SURNAME_1 , ID, l_transaction);
END;

