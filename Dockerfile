FROM odoo:20.0

USER root
COPY custom_addons /mnt/extra-addons
COPY entrypoint.sh /entrypoint-cloud.sh
RUN chmod +x /entrypoint-cloud.sh && chown -R odoo:odoo /mnt/extra-addons

USER odoo
EXPOSE 8069 8072
ENTRYPOINT ["/entrypoint-cloud.sh"]
CMD []
