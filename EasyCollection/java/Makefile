GEN=OscilloscopeMsg.java Constants.java

all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

OscilloscopeMsg.java: ../EasyCollection.h
	mig -target=null -java-classname=OscilloscopeMsg java ../EasyCollection.h oscilloscope -o $@

Constants.java: ../EasyCollection.h
	ncg -target=null -java-classname=Constants java ../EasyCollection.h NREADINGS DEFAULT_INTERVAL -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)
	rm result.txt

veryclean: clean
	rm oscilloscope.jar
