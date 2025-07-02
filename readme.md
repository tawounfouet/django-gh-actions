
```sh
python3.11 -m venv .venv
source .venv/bin/activate

touch .gitignore
echo ".venv" >> .gitignore

git init


# Install django 4
pip install django==4.2.16

# setup django project
django-admin startproject core .

# Create a new app
python manage.py startapp posts