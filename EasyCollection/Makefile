COMPONENT=EasyCollectionAppC
CFLAGS += -I$(TOSDIR)/lib/net \
                   -I$(TOSDIR)/lib/net/le \
                   -I$(TOSDIR)/lib/net/ctp
BUILD_EXTRA_DEPS += EasyCollection.class
CLEAN_EXTRA = *.class EasyCollectionMsg.java

EasyCollection.class: $(wildcard *.java) EasyCollectionMsg.java
	javac *.java
EasyCollectionMsg.java:
	mig java -target=null -java-classname=EasyCollectionMsg EasyCollection.h EasyCollectionMsg -o $@
clean :
	rm EasyCollection.class EasyCollectionMsg.java 
include $(MAKERULES)
