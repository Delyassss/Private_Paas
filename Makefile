

all : check_folders up



check_folders : 
	@if [ ! -d ./repos ]; then \
			echo "Creating the repo folder ...";\
				mkdir ./repos; \
		fi
	@if [ ! -d ./apps ]; then \
			echo "Creating the app folder ..."; \
				mkdir ./apps;\
		fi
	@if [ ! -d ./scripts ]; then \
			echo "Creating the scripts folder ..."; \
			mkdir ./scripts; \
		fi

up : 

	./scripts/init-paas.sh
	@echo "NGINX is up and running as well as the network"


fclean :
	@echo "Removing containers ...";

	@if [ -f ./containers/name.log ];
		then \
		docker rm -f $$(cat ./containers/name.log); \
	fi