JPR le 07/10/2021

Pour générer la liste des paramètres afins de produire un fichier RULES pour le checker JAVA, il faut:

- récupérer la liste Argo sur le site (argo-parameters-list-core-and-b_20210708.xlsx)
- remplacer les retour chariot par des espaces (ATL 010)
- masquer les colonnes non utilisées
- enlever les .f dans les min/max et les fillValue
- remplacer les SDN:P061 par SDN:P06
- masquer les lignes des paramètres avec des TEMPLATE (NB_SAMPLE_<parameter_sensor_name>)

=> copier coller dans un .txt pour exploitation

- récupérer la liste spécifique (glider_specific_parameters_list_20210906.xlsx)
- ajouter la colonne order
- ignorer FLUORESCENCE_VOLTAGE_CHLA lors de la copie de son contenu au fichier .txt à exploiter

dans le fichier .xml produit, remplacer SDN:P06 par SDN:P061 sur les quelques paramètres qui ne sont pas venus des listes.
