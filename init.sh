echo "CUID=$(id -u)" > .env
echo "CGID=$(id -g)" >> .env
echo "CU=$(id -un)" >> .env
echo "CG=$(id -gn)" >> .env
