-- Configuracoes
INSERT INTO "settings" ("name", "value", "updated_on") VALUES ('default_language', 'pt-BR', '2016-06-06 16:01:25');
INSERT INTO "settings" ("name", "value", "updated_on") VALUES ('force_default_language_for_anonymous', '1', '2016-06-06 16:01:25');
INSERT INTO "settings" ("name", "value", "updated_on") VALUES ('force_default_language_for_loggedin', '1', '2016-06-06 16:01:26');
INSERT INTO "settings" ("name", "value", "updated_on") VALUES ('default_projects_modules',E'---  \n  - issue_tracking  \n  - time_tracking  \n  - news  \n  - documents  \n  - files  \n  - wiki  \n  - repository  \n  - boards  \n  - calendar  \n  - gantt  \n  - agile  \n  ','2016-02-26 11:55:04');

-- Tipos
UPDATE "trackers" SET "name" = 'Defeito' WHERE "trackers"."id" = 1;

INSERT INTO "trackers" ("name", "default_status_id", "is_in_roadmap", "position") VALUES ('Melhoria', 1, '0', 4);

-- Fluxo de trabalho de Melhoria
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id, author, assignee, field_name, "rule", type) SELECT 4, 1, old_status_id, new_status_id, author, assignee, field_name, "rule", type FROM workflows WHERE tracker_id = 2 AND role_id = 1;
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id, author, assignee, field_name, "rule", type) SELECT 4, 3, old_status_id, new_status_id, author, assignee, field_name, "rule", type FROM workflows WHERE tracker_id = 2 AND role_id = 3;
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id, author, assignee, field_name, "rule", type) SELECT 4, 4, old_status_id, new_status_id, author, assignee, field_name, "rule", type FROM workflows WHERE tracker_id = 2 AND role_id = 4;
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id, author, assignee, field_name, "rule", type) SELECT 4, 5, old_status_id, new_status_id, author, assignee, field_name, "rule", type FROM workflows WHERE tracker_id = 2 AND role_id = 5;

-- Estados da tarefa
INSERT INTO "issue_statuses" ("name", "position") VALUES ('Suspensa', 7);

-- Fluxo de trabalho do Gestor
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 1, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 1, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 1, 3);

INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 2, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 2, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 2, 3);

INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 3, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 3, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 3, 3);

INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 4, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 4, 3);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 4, 3);

-- Fluxo de trabalho do Programador
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 1, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 1, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 1, 4);

INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 2, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 2, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 2, 4);

INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 3, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 3, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 3, 4);

INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 1, 7, 4, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 2, 7, 4, 4);
INSERT INTO "workflows" ("type", "old_status_id", "new_status_id", "tracker_id", "role_id") VALUES ('WorkflowTransition', 7, 2, 4, 4);

-- Dumping data for table "custom_fields"
INSERT INTO "custom_fields" VALUES
(1,'IssueCustomField','Módulo','list',E'---  \n  - Arrecadação  \n  - Atendimento ao Público  \n  - Batch  \n  - Cadastro  \n  - Cobrança  \n  - Faturamento  \n  - Fechamento  \n  - Financeiro  \n  - Infraestrutura  \n  - Impressão Simultânea  \n  - Micromedição  \n  - Operacional  \n  - Relatórios  \n  - Segurança  \n  ','',NULL,NULL,'1','1','1',1,'1','Atendimento ao Público','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  url_pattern: ''''  \n  edit_tag_style: ''''  \n  ','Divisão dos Módulos do GSAN'),
(2,'IssueCustomField','Nota do atendimento','enumeration',NULL,'',NULL,NULL,'0','1','1',2,'0','','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  url_pattern: ''''  \n  edit_tag_style: ''''  \n  ',''),
(3,'IssueCustomField','Rotina afetada','string',NULL,'',NULL,100,'0','1','1',3,'1','Não se aplica','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  text_formatting: ''''  \n  url_pattern: ''''  \n  ',''),
(4,'IssueCustomField','Afeta receita','bool',NULL,'',NULL,NULL,'0','1','1',4,'0','','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  url_pattern: ''''  \n  edit_tag_style: check_box  \n  ','Se a rotina afetada implica na perda de receita'),
(5,'IssueCustomField','Criticidade','list',E'---  \n  - Baixa  \n  - Média  \n  - Alta  \n  ','',NULL,NULL,'0','1','1',5,'1','Baixa','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  url_pattern: ''''  \n  edit_tag_style: ''''  \n  ','Nível de criticidade'),
(6,'IssueCustomField','Complexidade','list',E'---  \n  - Baixa  \n  - Média  \n  - Alta  \n  ','',NULL,NULL,'0','1','1',6,'1','Baixa','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  url_pattern: ''''  \n  edit_tag_style: ''''  \n  ','Nível de complexidade com base no esforço necessário para a resolusão da não conformidade registrada'),
(7,'IssueCustomField','Grau de severidade','list',E'---  \n  - ''1''  \n  - ''2''  \n  - ''3''  \n  - ''4''  \n  - ''5''  \n  ','',NULL,NULL,'0','1','1',7,'1','1','1','1','0',E'--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess  \n  url_pattern: ''''  \n  edit_tag_style: ''''  \n  ','                          |      Complexidade  \n  Criticidade | Baixa | Média | Alta  \n  Baixa              |     1      |       2       |    3  \n  Média            |      2      |      3       |    4  \n  Alta                 |     3      |       4       |    5');

-- Dumping data for table "custom_fields_trackers"
INSERT INTO "custom_fields_trackers" VALUES (1,1),(1,2),(1,3),(1,4),(2,1),(2,2),(2,3),(2,4),(3,1),(3,2),(3,3),(3,4),(4,1),(4,2),(4,3),(4,4),(5,1),(5,2),(5,3),(5,4),(6,1),(6,2),(6,3),(6,4),(7,1),(7,2),(7,3),(7,4);

-- Dumping data for table "custom_field_enumerations"
INSERT INTO "custom_field_enumerations" VALUES (1,2,'0 - Não atendeu','1',0),(2,2,'5 - Atendeu parcialmente','1',1),(3,2,'10 - Atendeu completamente','1',2);
