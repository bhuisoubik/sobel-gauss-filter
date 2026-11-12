IVFLAGS = -g2012 -Wall

golden:
	python model/golden.py

clean:
	rm -rf sim/*