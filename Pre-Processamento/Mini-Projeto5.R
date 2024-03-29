# Mini-Projeto 5 - Text Analytics Para Analisar a Reação do Mercado Sobre as Notícias de Uma Empresa

# Leia o manual em pdf no Capítulo 12 com a descrição do projeto

# Diretório de Trabalho
setwd("C:/Users/lets/OneDrive/Documentos/FCD/5-BusinessAnalytics/Cap12_Text_Analytics/Mini-Projeto5")
getwd()

# Pacotes
library(tm)
library(topicmodels)
library(textdata)
library(rvest)
library(tidyverse)
library(tidytext)
library(dplyr)
library(tidyr)
library(reshape2)
library(forcats)
library(scales)
library(stringr)
library(ggplot2)
library(wordcloud)
library(igraph)
library(ggraph)

########## Extração dos Dados de Texto via Web Scraping ##########

# Web Scraping do site do New York Times
?read_html
artigo_nytimes <- read_html("https://www.nytimes.com/2021/02/01/business/gamestop-how-much-worth.html")
class(artigo_nytimes)
View(artigo_nytimes)

# Obtendo o título do artigo
titulo_artigo_nytimes <- artigo_nytimes %>%
  html_nodes("title") %>%
  html_text()

# Visualizando o título
print(titulo_artigo_nytimes)

# Extraindo o texto do artigo
texto_artigo_nytimes <- artigo_nytimes %>%
  html_nodes("p") %>%
  html_text()

# Visualizando o texto
class(texto_artigo_nytimes)
View(texto_artigo_nytimes)

# Web Scraping do site do Yahoo Finance
artigo_yahoo <- read_html("https://finance.yahoo.com/news/gamestop-amc-reddit-investing-213609595.html")

# Obtendo o título do artigo
titulo_artigo_yahoo <- artigo_yahoo %>%
  html_nodes("title") %>%
  html_text()

# Visualizando o título
print(titulo_artigo_yahoo)

# Extraindo o texto do artigo
texto_artigo_yahoo <- artigo_yahoo %>%
  html_nodes("p")%>%
  html_text()

# Visualizando o texto
View(texto_artigo_yahoo)

# Web Scraping do site da Time Magazine
artigo_timemag <- read_html("https://time.com/5933242/gamestop-stock-gme/")

# Obtendo o título do artigo
titulo_artigo_timemag <- artigo_timemag %>%
  html_nodes("title") %>%
  html_text()

# Visualizando o título
print(titulo_artigo_timemag)

# Extraindo o texto do artigo
texto_artigo_timemag <- artigo_timemag %>%
  html_nodes("p") %>%
  html_text()

# Visualizando o texto
View(texto_artigo_timemag)

########## Preparação dos Dados ##########

# Vamos criar um dataframe para o texto de cada artigo

df_nytimes <- data.frame(line = 1, text = texto_artigo_nytimes, stringsAsFactors = FALSE)
class(df_nytimes)
View(df_nytimes)

df_yahoo <- data.frame(line = 1, text = texto_artigo_yahoo, stringsAsFactors = FALSE)
View(df_yahoo)

df_timemag <- data.frame(line = 1, text = texto_artigo_timemag, stringsAsFactors = FALSE)
View(df_timemag)

########## Processamento de Linguagem Natural ##########

# Tokenização

?unnest_tokens
?dplyr::anti_join

tokens_nytimes <- df_nytimes %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE)

View(tokens_nytimes)

tokens_yahoo <- df_yahoo %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE)

View(tokens_yahoo)

tokens_timemag <- df_timemag %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE)

View(tokens_timemag)

# Histogramas de Frequência

# Vamos verificar quais palavras aparecem com mais frequência

hist_nytimes <- df_nytimes %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE) %>%
  filter(n > 6) %>% 
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()

print(hist_nytimes + ggtitle("Histograma de Frequência do Artigo do New York Times"))

hist_yahoo <- df_yahoo %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE) %>%
  filter(n > 13) %>% 
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()

print(hist_yahoo + ggtitle("Histograma de Frequência do Artigo do Yahoo Finance"))

hist_timemag <- df_timemag %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(word, sort = TRUE) %>%
  filter(n > 3) %>% 
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()

print(hist_timemag + ggtitle("Histograma de Frequência do Artigo da Time Magazine"))

# Removendo as Stop Words

nytimes_clean <- df_nytimes %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) 

yahoo_clean <- df_yahoo %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words)

timemag_clean <- df_timemag %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words)

# Combinando os Dataframes

# Calculamos a frequência
?bind_rows
?str_extract
frequencia <- bind_rows(mutate(nytimes_clean, author = "NYTIMES"),
                        mutate(yahoo_clean, author = "YAHOO"),
                        mutate(timemag_clean, author = "TIME")) %>%
  mutate(word = str_extract(word, "[a-z']+")) %>%
  count(author, word) %>%
  group_by(author) %>%
  mutate(proportion = n/sum(n))%>%
  select(-n) %>%
  spread(author, proportion) %>%
  gather(author, proportion, `TIME`, `NYTIMES`)

print(frequencia)

# Plot de um Correlograma para comparar os artigos
ggplot(frequencia, aes(x = proportion, y = `YAHOO`, color = abs(`YAHOO`- proportion))) +
  geom_abline(color = "grey40", lty = 2) +
  geom_jitter(alpha = .1, size = 2.5, width = 0.3, height = 0.3) +
  geom_text(aes(label = word), check_overlap = TRUE, vjust = 1.5) +
  scale_x_log10(labels = percent_format()) +
  scale_y_log10(labels= percent_format()) +
  scale_color_gradient(limits = c(0,0.001), low = "darkslategray4", high = "gray75") +
  facet_wrap(~author, ncol=2) +
  theme(legend.position = "none") +
  labs(y = "Yahoo", x = NULL)

# Correlação entre os artigos do Yahoo e NYTimes
cor.test(data = frequencia[frequencia$author == "NYTIMES",], ~proportion + `YAHOO`)  

# Correlação entre os artigos do Yahoo e Time
cor.test(data = frequencia[frequencia$author == "TIME",], ~proportion + `YAHOO`)

########## Análise de Sentimentos ##########

# Léxicos de sentimentos
?get_sentiments
afinn <- get_sentiments("afinn")
nrc <- get_sentiments("nrc")
bing <- get_sentiments("bing")

# Análise de sentimentos do artigo do New York Times

# Método AFINN
nytimes_clean %>%
  inner_join(get_sentiments("afinn")) %>%
  summarise(sentiment = sum(value)) %>%
  mutate(method = "AFINN")

# Método Bing
nytimes_clean %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = T)

# Método NRC
sentimentos_nytimes <- nytimes_clean %>%
  inner_join(get_sentiments("nrc")) %>%
  count(word, sentiment, sort = T) %>%
  ungroup()

# Plot de todos os sentimentos
sentimentos_nytimes %>%
  group_by(sentiment) %>%
  top_n(10) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Sentimentos do Artigo do New York Times", x = NULL) +
  coord_flip()

# Palavras mais associadas a sentimentos positivos
sentimentos_nytimes %>%
  group_by(sentiment) %>%
  filter(sentiment == "positive") %>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) + ggtitle("Palavras Mais Associadas a Sentimentos Positivos") +
  geom_col(show.legend = FALSE, fill = "palegreen2") +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Frequência", x = NULL) +
  coord_flip()

# Palavras mais associadas a sentimentos negativos
sentimentos_nytimes %>%
  group_by(sentiment) %>%
  filter(sentiment == "negative") %>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) + ggtitle("Palavras Mais Associadas a Sentimentos Negativos") +
  geom_col(show.legend = FALSE, fill = "red3") +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Frequência", x = NULL) +
  coord_flip()

# Análise de sentimentos do artigo do Yahoo Finance

# Método AFINN
yahoo_clean %>%
  inner_join(get_sentiments("afinn")) %>%
  summarise(sentiment = sum(value)) %>%
  mutate(method = "AFINN")

# Método Bing
yahoo_clean %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = T)

# Método NRC
sentimentos_yahoo <- yahoo_clean %>%
  inner_join(get_sentiments("nrc")) %>%
  count(word, sentiment, sort = T) %>%
  ungroup()

# Plot de todos os sentimentos
sentimentos_yahoo %>%
  group_by(sentiment) %>%
  top_n(8) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Sentimentos do Artigo do Yahoo Finance", x = NULL) +
  coord_flip()

# Palavras mais associadas a sentimentos positivos
sentimentos_yahoo %>%
  group_by(sentiment) %>%
  filter(sentiment == "positive") %>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) + ggtitle("Palavras Mais Associadas a Sentimentos Positivos")+
  geom_col(show.legend = FALSE, fill = "palegreen2") +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Frequência", x = NULL) +
  coord_flip()

# Palavras mais associadas a sentimentos negativos
sentimentos_yahoo %>%
  group_by(sentiment) %>%
  filter(sentiment == "negative") %>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word=reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) + ggtitle("Palavras Mais Associadas a Sentimentos Negativos") +
  geom_col(show.legend = FALSE, fill = "red3") +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Frequência", x = NULL) +
  coord_flip()

# Análise de sentimentos do artigo da Time Magazine

# Método AFINN
timemag_clean %>%
  inner_join(get_sentiments("afinn")) %>%
  summarise(sentiment = sum(value)) %>%
  mutate(method = "AFINN")

# Método Bing
timemag_clean %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = T)

# Método NRC
sentimentos_timemag <- timemag_clean %>%
  inner_join(get_sentiments("nrc")) %>%
  count(word, sentiment, sort = T) %>%
  ungroup()

# Plot de todos os sentimentos
sentimentos_timemag %>%
  group_by(sentiment) %>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Sentimentos do Artigo da Time Magazine", x = NULL) +
  coord_flip()

# Palavras mais associadas a sentimentos positivos
sentimentos_timemag %>%
  group_by(sentiment) %>%
  filter(sentiment == "positive") %>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word=reorder(word, n)) %>%
  ggplot(aes(word, n, fill=sentiment)) + ggtitle("Palavras Mais Associadas a Sentimentos Positivos")+
  geom_col(show.legend = FALSE, fill = "palegreen2") +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Frequência", x = NULL) +
  coord_flip()

# Palavras mais associadas a sentimentos negativos
sentimentos_timemag %>%
  group_by(sentiment) %>%
  filter(sentiment == "negative")%>%
  top_n(5) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) + ggtitle("Palavras Mais Associadas a Sentimentos Negativos") +
  geom_col(show.legend = FALSE, fill = "red3") +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Frequência", x = NULL) +
  coord_flip()

# Encontrando as Palavras Mais Comuns nos Textos Usando TF-IDF

# Combinando os artigoos
df_combinado <- bind_rows(mutate(df_nytimes, author = "Yahoo"),
                          mutate(df_yahoo, author = "TIME"),
                          mutate(df_timemag, author = "NYtimes"))

# Remoção de stop words e tokenização
df_combinado_limpo <- df_combinado %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(author, word, sort = TRUE) %>%
  ungroup()

# Total de palavras
total_palavras <- df_combinado_limpo %>%
  group_by(author) %>%
  summarize(total = sum(n))

# Left join
df_combinado_limpo <- left_join(df_combinado_limpo, total_palavras)

# TF-IDF
?bind_tf_idf
df_tf_idf <- df_combinado_limpo %>%
  bind_tf_idf(word, author, n)

View(df_tf_idf)

# Plot das palavras mais frequentes usando TF-IDF
df_tf_idf %>%
  arrange(desc(tf_idf)) %>%
  mutate(word = factor(word, levels = rev(unique(word)))) %>%
  group_by(author) %>%
  top_n(10) %>%
  ungroup() %>%
  ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = author)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~author, ncol = 2, scales = "free") +
  labs(x = "Palavras Mais Frequentes", y = NULL)


# Word Clouds

# Remoção de stop words e tokenização
df_combinado2 <- df_combinado %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  count(author, word, sort = TRUE)

# Plot com NRC
df_combinado2 %>%
  inner_join(get_sentiments("nrc")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("gray20", "gray80"), max.words = 200)

# Plot com Bing
df_combinado2 %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("gray20", "gray80"), max.words = 200)

########### Modelagem de Tópicos ###########

# Criando a Document Term Matrix para todos os artigos
doc_term_matrix <- df_combinado %>%
  unnest_tokens(word, text) %>%
  count(author, word) %>%
  cast_dtm(author, word, n)

print(doc_term_matrix)

dtm_artigos <- df_combinado_limpo %>%
  cast_dtm(author, word, n)

# LDA (Latent Dirichlet Allocation)
?LDA
modelo_lda <- LDA(dtm_artigos, k = 3, control = list(seed = 123))
modelo_lda

# Dataframe de tópicos
df_topics <- tidy(modelo_lda, matrix = "beta")
print(df_topics)

# Top termos
top_termos <- df_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

# Tópicos - Top Termos
top_termos %>%
  mutate(term = reorder(term, beta)) %>% 
  ggplot(aes(term, beta, fill = factor(topic))) + 
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") + 
  coord_flip()

# Conclusão: Não há evidência que demonstre reação positiva ou negativa do mercado com relação aos artigos
# analisados. O objetivo principal dos artigos parece estar em prover informação mantendo um tom neutro,
# levemente positivo.







