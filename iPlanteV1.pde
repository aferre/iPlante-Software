
int lumi_pin=0;
int temp_in_pin=1;

void setup() {
  Serial.begin(9600); // See "Enhancements" above to learn when to change this.
}

void loop() {
  int light_level=analogRead(lumi_pin);
  light_level = map(light_level,0,900,0,255);
  light_level = constrain(light_level,0,255);
  
  float temp = analogRead(temp_in_pin)*.004882814;
  temp = (temp - .5) * 100;
    Serial.print("L:");
    Serial.print(light_level);
    Serial.print(" TI:");
    Serial.print(temp);
    Serial.println("");
   // Serial.print((char *) "L:" + (int) light_level + "TI:" + (float) temp);
    delay(1000);
}
