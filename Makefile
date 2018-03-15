plan: messenger terraform.tf
	terraform plan --out=terraform.plan

deploy: terraform.plan
	terraform apply terraform.plan

messenger: build/messenger.zip

build/messenger.zip: src/messenger.py src/requirements.txt
	mkdir -p build/
	cp -r src/* build/
	rm -f build/messenger.zip
	cd build && pip install -r requirements.txt --target . && zip -r messenger.zip .

clean:
	rm -rf build
