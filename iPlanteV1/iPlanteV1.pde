#include <EEPROM.h>
#include <avr/eeprom.h>
#include <Time.h>

typedef struct _conf_struct{
  int nbRecords;
  time_t lastUpdateDate;
} 
configuration;

typedef struct _record_struct{
  time_t time;
  int light_level;
  float tempExt;
  float tempInt;
  int humidity;
} 
record;

int lumi_pin=0;
int temp_in_pin=1;

int w_addr=0;
#define EEPROM_SPACE 1024
#define MAX_RECORDS 100
#define CMD_MAX 4
char cmdBuffer[CMD_MAX];

boolean hasSerial;

void setup() {
  Serial.begin(19200); // See "Enhancements" above to learn when to change this.
  checkSerial();
  setTime(10,10,10,10,10,2010);
}

int getLastAvailableAddress(){
  configuration conf;
  eeprom_read_block((void*)&conf, (void*)0, sizeof(configuration));

  int address = 0;
  address += sizeof(configuration);
  int nbRec = conf.nbRecords;
  address += nbRec*sizeof(record);
  return address;
}

//sends a ping (letter P) every seconds.
//if there is no response for 10 seconds, assumes no serial connection so the board is in the monitored plante.
void checkSerial(){
  hasSerial = false;
  int time=0;
  while (Serial.available()<=0){
    Serial.print("Waiting for ");   // send a capital P  
    Serial.print(10 - time/1000);
    Serial.println("...");
    delay(1000);
    time +=1000;
    if (time==10000){
      return;
    }
  }
  hasSerial = true;
}

void captureAndStore(){
  Serial.println("Capturing");

  record rec;

  //  rec.time = now();

  rec.light_level = getLightLevel();

  Serial.println("got light");
  delay(10);
  rec.tempExt = getExtTemp();

  Serial.println("got ext");
  delay(10);
  rec.tempInt = getInTemp();

  Serial.println("got in");
  delay(10);
  rec.humidity = getLightLevel();

  Serial.println("got humidity");
  configuration conf;
  eeprom_read_block((void*)&conf, (void*)0, sizeof(configuration));
  Serial.println("red conf");

  if (getLastAvailableAddress() + sizeof(rec)>EEPROM_SPACE)
    eeprom_write_block((const void*)&rec, (void*)sizeof(configuration), sizeof(rec));
  else
    eeprom_write_block((const void*)&rec, (void*)getLastAvailableAddress(), sizeof(rec));
  Serial.println("wrote rec");

  int nbRec = conf.nbRecords;
  if (nbRec == MAX_RECORDS) {

  }
  else {
    nbRec ++;
    conf.nbRecords =  nbRec;
    eeprom_write_block((const void*)&conf, (void*)0, sizeof(configuration));
  }
  Serial.println("wrote conf");

}

void dumpRecordsToSerial(){
  int nbRec=0;
  configuration conf;
  eeprom_read_block((void*)&conf, (void*)0, sizeof(configuration));
  nbRec = conf.nbRecords;

  //for (int i=1;i<=nbRec ;i++)
   for (int i=1;i<=10 ;i++){
    printRecord(i,false);
   if (i!=10) Serial.print(";");  
 }
  Serial.println();
}

void printRecord(int recordNumber,boolean carriage){
  record rec;
  eeprom_read_block((void*)&rec, (void*)(sizeof(configuration) + recordNumber*sizeof(record)), sizeof(record));

  Serial.print("R");
  Serial.print(recordNumber);
  Serial.print(":");
  Serial.print("Date:");
  Serial.print(day(rec.time));
  Serial.print("/");
  Serial.print(month(rec.time));
  Serial.print("/");
  Serial.print(year(rec.time));
  Serial.print(",");
  Serial.print(hour(rec.time));
  Serial.print(":");
  Serial.print(minute(rec.time));
  Serial.print(":");
  Serial.print(second(rec.time));
  Serial.print(",T1:");
  Serial.print(rec.tempInt);
  Serial.print(",T2:");
  Serial.print(rec.tempExt);
  Serial.print(",Lumi:");
  Serial.print(rec.light_level);
  Serial.print(",Humi:");
  if (carriage) Serial.println(rec.humidity);
  else Serial.print(rec.humidity);
}

void writeRecordsNumber(){

}

int getLightLevel(){
  int light_level=analogRead(lumi_pin);
  light_level = map(light_level,0,900,0,255);
  light_level = constrain(light_level,0,255);
  return light_level;
}

float getExtTemp(){
  float temp = analogRead(temp_in_pin)*.004882814;
  temp = (temp - .5) * 100;
  return temp;
}

float getInTemp(){
  float temp = analogRead(temp_in_pin)*.004882814;
  temp = (temp - .5) * 100;
  return temp;
}

void clearEEPROM(){
  for (int i = 0; i < 512; i++)
    EEPROM.write(i, 0);
}

void clearCommand(){
  for (int i=0;i<100;i++) cmdBuffer[i]=' ';
}

void loop() {

  if (hasSerial){
    if(Serial.available()>=CMD_MAX) {    
      int i=0;
      for (i=0;i<CMD_MAX;i++) {
        cmdBuffer[i]=Serial.read();
      }
    }

    if (cmdBuffer[0] == 'R' && cmdBuffer[1] == 'A'){
      Serial.print("RA");
      dumpRecordsToSerial();
    } 
    else if (cmdBuffer[0] == 'R' && cmdBuffer[1] == 'N'){
      writeRecordsNumber();
    } 
    else if (cmdBuffer[0] == 'R' && cmdBuffer[1] == 'E'){
      clearEEPROM();
    } 
    else if (cmdBuffer[0] == 'R'){
      int nbRec = 0;
      nbRec = nbRec + (cmdBuffer[1]-48)*100;
      nbRec = nbRec + (cmdBuffer[2] -48)*10;
      nbRec = nbRec + (cmdBuffer[3] - 48);
      printRecord(nbRec,true);
    }
    else if (cmdBuffer[0] == 'C' && cmdBuffer[1] == 'A'){
      captureAndStore();
    }
    clearCommand();
    delay(100);
  }
  else{
    //No serial
    //sleep and capture/store loop
    //captureAndStore();
    delay(1000);
  } 
}

