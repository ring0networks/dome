.IGNORE: clean
.PHONY: all clean

all:
	vagrant up --provider=virtualbox dome

clean:
	vagrant destroy dome
	bash -c "rm -rf ./.vagrant"
