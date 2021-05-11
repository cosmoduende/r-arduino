
# REQUIRED LIBRARIES

library(tidyverse)
library(serial)
library(magrittr)
library(plotly)

listPorts()

# SERIAL CONNECTION

myArduino <-  serialConnection(
  port = "cu.usbmodem1421",
  mode = "9600,n,8,1" ,
  buffering = "none",
  newline = TRUE,
  eof = "",
  translation = "cr",
  handshake = "none",
  buffersize = 4096
)

# OPEN AND TESTING THE CONNECTION

open(myArduino)
isOpen(myArduino)

# MAKING RGB DATA

n <-  30

arduinoInput <- tibble(
  r = (sample(1:100, size = n, replace = T) %>%
         paste('R', sep = '')),
  g = (sample(1:100, size = n, replace = T) %>%
         paste('G', sep = '')),
  b = (sample(1:100, size = n, replace = T) %>%
         paste('B', sep = ''))
)

# A GLIMPSE OF ARDUINO INPUT

glimpse(arduinoInput)

# CLOSE THE OPEN CONNECTION AGAIN (BEST PRACTICE)

close(myArduino)
open(myArduino)

# GIVING TIME FOR THE BOARD TO RESET ONCE THE SERIAL INTERFACE IS INITIATED

Sys.sleep(3)

for (r in seq_len(n)){
  Sys.sleep(0.25)
  write.serialConnection(myArduino, paste(arduinoInput[r,], collapse = ''))
}

# READ MAPPED DATA SENT FROM MY ARDUINO

dataFromArduino <- tibble(
  capture.output(cat(read.serialConnection(myArduino,n=0)))
) 

# SELECT FIRST NINE ROWS, ASSIGN VALUES TO THEIR LEDS AND RENAME FIRST COLUMN

dataFromArduino %>% 
  slice_head(n = 9)

# ASSIGN VALUES TO LEDS AND CHANGE COLUMN NAME

dataFromArduino %<>% 
  tibble(ledNames = rep_along(seq_len(nrow(dataFromArduino)), 
                         c('rMapped','gMapped','bMapped'))) %>%
  rename("ledVal" = 1) %>%
  group_by(ledNames) %>%
 
   # ADD IDENTIFIERS REQUIRED BY PIVOT_WIDER FUNCTION AND CREATE NEW COLUMNS WITH 'LEDVAL' VALUES
 
  mutate(row = row_number()) %>%
  pivot_wider(names_from = ledNames, values_from = ledVal) %>%
  
  # DROPPING 'ROW' COLUMN AND CONVERT ALL COLUMNS TO DATA TYPE INTEGER 
  
  select(-row) %>%
  mutate_all(as.integer)

dataFromArduino %>% 
  slice_head(n = 10)

# MERGE THE TWO DATA SETS,  DROP NON NUMERICAL CHARACTERS (R,G,B), AND REORDER COLUMNS

combinedData <- as_tibble(cbind(arduinoInput, dataFromArduino)) %>%
  mutate(across(where(is.character), ~parse_number(.x)), across(where(is.double), as.integer)) %>% 
  select(c(1, 4, 2, 5, 3, 6))

combinedData %>%
  slice_head(n = 10)


# CREATING NEW DATA SET THAT SELECTS VALUES IN ORDER: MAXIMUM OF RECEIVED LED VALUES, THEN MINIMUM, AND SO IS REPEATED

rowMin <- tibble(inputMin = dataFromArduino %>% apply(1,min)) %>%
  
  # SELECT EVEN ROWS
  
  filter(row_number() %% 2 == 0)

servoInput <- tibble(servoIn = dataFromArduino %>% 
                       apply(1,max)) 

# REPLACE EVEN ROWS WITH A MINIMUM VALUE, AND APPENDING A TERMINATING CHARACTER 

servoInput[c(1:n)[c(F,T)],] <- rowMin

servoInput %<>% 
  mutate(servoIn = servoIn %>% 
           paste('S', sep = ''))

close(myArduino)
open(myArduino)

Sys.sleep(1)

for (r in seq_len(n)){
  Sys.sleep(1)
  write.serialConnection(myArduino, paste(servoInput[r,], collapse = ''))
}

# READ MAPPED ANGLES SENT FROM MY ARDUINO, RENAME FIRST COLUMN

angleFromServo <- tibble(
  capture.output(cat(read.serialConnection(myArduino,n=0)))) %>%
  rename("servoAnglesMapped" = 1) %>% 
  mutate_all(as.integer)

# SELECT FIRST TEN ROWS

angleFromServo %>% 
  slice_head(n = 10)

# WHAT WE SENT VS WHAT WE RECEIVED. MERGE THE TWO DATA SETS AND DROP NON NUMERIC CHARACTER 'S'

combinedAngles <- as_tibble(
  cbind(servoInput, angleFromServo)) %>%
  mutate(across(where(is.character), ~parse_number(.x)),
         across(where(is.double), as.integer))

combinedAngles %>%
  slice_head(n = 10)

# PLOT VARIATION OF SERVO ANGLE

theme_set(theme_light())

myPlot <- angleFromServo %>%
  ggplot(mapping = aes(x = 1:nrow(angleFromServo), y = servoAnglesMapped)) +
  geom_line() +
  geom_smooth(se = F) +
  labs(x = "Count", y = "Servo angle",  title = "Servo angle variation at each count instance")+
  theme(plot.title = element_text(hjust = 0.5))

ggplotly(myPlot)
