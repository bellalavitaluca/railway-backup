FROM postgres:16-alpine

RUN apk add --no-cache aws-cli bash

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

CMD ["/backup.sh"]
